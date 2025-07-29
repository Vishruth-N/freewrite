import Speech
import AVFoundation

class SpeechService: ObservableObject {
    @Published var isRecording = false
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    private var baseTextBeforeDictation = ""
    private var currentPartialText = ""
    private var userEditedDuringRecording = false
    private var isProcessingUserEdit = false
    private var retryCount = 0
    private let maxRetries = 2
    
    var onTextUpdate: ((String) -> Void)?
    var onTextChanged: ((String, Bool) -> Void)? // text, isUserEdit
    
    private func resetSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    func startDictation(currentText: String) {
        
        // Reset retry count only if this is a fresh start (not a retry)
        if !isRecording {
            retryCount = 0
        }
        
        // Try to reset speech recognizer if not available
        if speechRecognizer == nil || !speechRecognizer!.isAvailable {
            resetSpeechRecognizer()
        }
        
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
        
        // Try on-device first, then cloud on retry
        if retryCount == 0 && speechRecognizer.supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = true
        } else {
            recognitionRequest.requiresOnDeviceRecognition = false  
        }
        
        if #available(macOS 13.0, *) {
            recognitionRequest.addsPunctuation = true
        }
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        baseTextBeforeDictation = currentText
        userEditedDuringRecording = false
        isProcessingUserEdit = false
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            DispatchQueue.main.async {
                guard self.isRecording else { 
                    return 
                }
                
                if let result = result {
                    // Reset retry count on successful result
                    if self.retryCount > 0 {
                        self.retryCount = 0
                    }
                    
                    guard !self.isProcessingUserEdit else { 
                        return 
                    }
                    
                    let transcribedText = result.bestTranscription.formattedString
                    
                    if self.userEditedDuringRecording {
                        self.isProcessingUserEdit = true
                        self.baseTextBeforeDictation = currentText
                        self.currentPartialText = ""
                        self.userEditedDuringRecording = false
                        self.stopRecording()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            self.isProcessingUserEdit = false
                            self.startRecording(currentText: currentText)
                        }
                        return
                    }
                    
                    if result.isFinal {
                        if !transcribedText.isEmpty {
                            let newText = self.baseTextBeforeDictation + transcribedText + " "
                            self.onTextUpdate?(newText)
                            self.baseTextBeforeDictation = newText
                        }
                        self.currentPartialText = ""
                        
                        self.isProcessingUserEdit = true
                        self.stopRecording()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            self.isProcessingUserEdit = false
                            self.startRecording(currentText: self.baseTextBeforeDictation)
                        }
                    } else {
                        self.currentPartialText = transcribedText
                        let newText = self.baseTextBeforeDictation + transcribedText
                        self.onTextUpdate?(newText)
                    }
                }
                
                if let error = error {
                    
                    // Check if it's a service error that we can retry
                    let nsError = error as NSError
                    if (nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1101) || 
                       (nsError.domain == "kAFAssistantErrorDomain") {
                        
                        if self.retryCount < self.maxRetries {
                            self.retryCount += 1
                            
                            // Stop current recording and retry
                            if self.isRecording {
                                self.stopRecording()
                            }
                            
                            // Retry after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.startDictation(currentText: self.baseTextBeforeDictation)
                            }
                            return
                        } else {
                            self.retryCount = 0
                        }
                    }
                    
                    // For other errors or max retries reached, stop recording
                    if self.isRecording {
                        self.stopRecording()
                    }
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
            stopRecording()
        }
    }
    
    func stopDictation() {
        retryCount = 0  // Reset retry count on manual stop
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
        
        if let onTextUpdate = onTextUpdate {
            let currentText = baseTextBeforeDictation + (currentPartialText.isEmpty ? "" : currentPartialText)
            if !currentText.hasSuffix(" ") && !currentPartialText.isEmpty {
                onTextUpdate(currentText + " ")
            }
        }
        
        currentPartialText = ""
        baseTextBeforeDictation = ""
        userEditedDuringRecording = false
        isProcessingUserEdit = false
        
        isRecording = false
    }
    
    func handleTextChange(newText: String) {
        if isRecording {
            let expectedText = baseTextBeforeDictation + currentPartialText
            if newText != expectedText {
                userEditedDuringRecording = true
                baseTextBeforeDictation = newText
                currentPartialText = ""
            }
        }
    }
} 