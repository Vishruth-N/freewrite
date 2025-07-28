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
    
    var onTextUpdate: ((String) -> Void)?
    var onTextChanged: ((String, Bool) -> Void)? // text, isUserEdit
    
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
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        baseTextBeforeDictation = currentText
        userEditedDuringRecording = false
        isProcessingUserEdit = false
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            DispatchQueue.main.async {
                guard self.isRecording else { return }
                
                if let result = result {
                    guard !self.isProcessingUserEdit else { return }
                    
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
                
                if error != nil {
                    if self.isRecording {
                        self.stopRecording()
                    }
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
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