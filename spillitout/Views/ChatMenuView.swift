import SwiftUI

struct ChatMenuView: View {
    @Binding var showingChatMenu: Bool
    @Binding var didCopyPrompt: Bool
    let text: String
    let urlService: URLService
    @Environment(\.colorScheme) var colorScheme
    
    private var popoverBackgroundColor: Color {
        colorScheme == .light ? Color(NSColor.controlBackgroundColor) : Color(NSColor.darkGray)
    }
    
    private var popoverTextColor: Color {
        colorScheme == .light ? Color.primary : Color.white
    }
    
    var body: some View {
        VStack(spacing: 0) {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let isUrlTooLong = urlService.isUrlTooLong(for: trimmedText)
            
            if isUrlTooLong {
                Text("Hey, your entry is long. It'll break the URL. Instead, copy prompt by clicking below and paste into AI of your choice!")
                    .font(.system(size: 14))
                    .foregroundColor(popoverTextColor)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .frame(width: 200, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
                Divider()
                
                Button(action: {
                    urlService.copyPromptToClipboard(with: trimmedText)
                    didCopyPrompt = true
                }) {
                    Text(didCopyPrompt ? "Copied!" : "Copy Prompt")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundColor(popoverTextColor)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                
            } else if text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("hi. my name is farza.") {
                Text("Yo. Sorry, you can't chat with the guide lol. Please write your own entry.")
                    .font(.system(size: 14))
                    .foregroundColor(popoverTextColor)
                    .frame(width: 250)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else if text.count < 350 {
                Text("Please free write for at minimum 5 minutes first. Then click this. Trust.")
                    .font(.system(size: 14))
                    .foregroundColor(popoverTextColor)
                    .frame(width: 250)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                Button(action: {
                    showingChatMenu = false
                    urlService.openChatGPT(with: trimmedText)
                }) {
                    Text("ChatGPT")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundColor(popoverTextColor)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                
                Divider()
                
                Button(action: {
                    showingChatMenu = false
                    urlService.openClaude(with: trimmedText)
                }) {
                    Text("Claude")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundColor(popoverTextColor)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                
                Divider()
                
                Button(action: {
                    urlService.copyPromptToClipboard(with: trimmedText)
                    didCopyPrompt = true
                }) {
                    Text(didCopyPrompt ? "Copied!" : "Copy Prompt")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundColor(popoverTextColor)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
        .frame(minWidth: 120, maxWidth: 250)
        .background(popoverBackgroundColor)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
        .onChange(of: showingChatMenu) { newValue in
            if !newValue {
                didCopyPrompt = false
            }
        }
    }
} 