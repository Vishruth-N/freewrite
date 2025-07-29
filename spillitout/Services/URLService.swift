import Foundation
import AppKit

class URLService {
    
    func openChatGPT(with text: String) {
        let fullText = AppSettings.aiChatPrompt + "\n\n" + text
        
        if let encodedText = fullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://chat.openai.com/?m=" + encodedText) {
            NSWorkspace.shared.open(url)
        }
    }
    
    func openClaude(with text: String) {
        let fullText = AppSettings.claudePrompt + "\n\n" + text
        
        if let encodedText = fullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://claude.ai/new?q=" + encodedText) {
            NSWorkspace.shared.open(url)
        }
    }
    
    func copyPromptToClipboard(with text: String) {
        let fullText = AppSettings.aiChatPrompt + "\n\n" + text

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fullText, forType: .string)
    }
    
    func isUrlTooLong(for text: String) -> Bool {
        let gptFullText = AppSettings.aiChatPrompt + "\n\n" + text
        let claudeFullText = AppSettings.claudePrompt + "\n\n" + text
        let encodedGptText = gptFullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedClaudeText = claudeFullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let gptUrlLength = "https://chat.openai.com/?m=".count + encodedGptText.count
        let claudeUrlLength = "https://claude.ai/new?q=".count + encodedClaudeText.count
        
        return gptUrlLength > 6000 || claudeUrlLength > 6000
    }
} 