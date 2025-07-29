import Speech
import AVFoundation

class SpeechService: ObservableObject {
    @Published var isRecording = false
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    private var currentText = ""
    
    var onTextUpdate: ((String) -> Void)?
    
    func startDictation(currentText: String) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.startRecording(currentText: currentText)
                }
            }
        }
    }
    
    private func startRecording(currentText: String) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            proceedWithRecording(currentText: currentText)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.proceedWithRecording(currentText: currentText)
                    }
                }
            }
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
    
    private func proceedWithRecording(currentText: String) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            return
        }
        
        // Clean up any existing session
        if isRecording {
            stopRecording()
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        if #available(macOS 13.0, *) {
            recognitionRequest.addsPunctuation = true
        }
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        // Store the initial text
        self.currentText = currentText
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            DispatchQueue.main.async {
                guard self.isRecording else { 
                    return 
                }
                
                if let result = result {
                    let transcribedText = result.bestTranscription.formattedString
                    
                    // Always append to the initial text
                    let newText = self.currentText + (transcribedText.isEmpty ? "" : transcribedText)
                    self.onTextUpdate?(newText)
                }
                
                if let error = error {
                    print("Speech recognition error: \(error)")
                    self.stopRecording()
                }
            }
        }
        
        if recognitionTask == nil {
            return
        }
        
        // Create a proper mono audio format for speech recognition
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Create a mono format with the same sample rate
        guard let monoFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, 
                                           sampleRate: recordingFormat.sampleRate, 
                                           channels: 1, 
                                           interleaved: false) else {
            stopRecording()
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            
            // Convert to mono if needed
            if recordingFormat.channelCount > 1 {
                // Convert multi-channel to mono by taking the first channel
                guard let monoBuffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: buffer.frameCapacity) else {
                    return
                }
                monoBuffer.frameLength = buffer.frameLength
                
                // Copy first channel to mono buffer
                if let sourceData = buffer.floatChannelData,
                   let destData = monoBuffer.floatChannelData {
                    memcpy(destData[0], sourceData[0], Int(buffer.frameLength) * MemoryLayout<Float>.size)
                }
                
                self.recognitionRequest?.append(monoBuffer)
            } else {
                // Already mono, use as-is
                self.recognitionRequest?.append(buffer)
            }
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Audio engine failed to start: \(error)")
            stopRecording()
        }
    }
    
    func stopDictation() {
        stopRecording()
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
    }
} 