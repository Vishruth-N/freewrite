import SwiftUI

struct UtilityButtonsSection: View {
    @Binding var timeRemaining: Int
    @Binding var timerIsRunning: Bool
    @Binding var showingChatMenu: Bool
    @Binding var didCopyPrompt: Bool
    @Binding var showingSidebar: Bool
    @ObservedObject var speechService: SpeechService
    @ObservedObject var preferencesService: PreferencesService
    let text: String
    let urlService: URLService
    let onNewEntry: () -> Void
    let onBottomNavHover: (Bool) -> Void
    
    @State private var isHoveringChat = false
    @State private var isHoveringNewEntry = false
    @State private var isHoveringThemeToggle = false
    @State private var isHoveringDictation = false
    @State private var isHoveringClock = false
    @State private var isHoveringReflect = false
    
    @StateObject private var appState = AppState.shared
    @Environment(\.colorScheme) var colorScheme
    
    private var textColor: Color {
        colorScheme == .light ? Color.gray : Color.gray.opacity(0.8)
    }
    
    private var textHoverColor: Color {
        colorScheme == .light ? Color.black : Color.white
    }
    
    var body: some View {
        HStack(spacing: 8) {
            TimerButtonView(timeRemaining: $timeRemaining, timerIsRunning: $timerIsRunning)
            
            Text("•")
                .foregroundColor(.gray)
            
            Button("Chat") {
                showingChatMenu = true
                didCopyPrompt = false
            }
            .buttonStyle(.plain)
            .foregroundColor(isHoveringChat ? textHoverColor : textColor)
            .onHover { hovering in
                isHoveringChat = hovering
                onBottomNavHover(hovering)
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .popover(isPresented: $showingChatMenu, attachmentAnchor: .point(UnitPoint(x: 0.5, y: 0)), arrowEdge: .top) {
                ChatMenuView(
                    showingChatMenu: $showingChatMenu,
                    didCopyPrompt: $didCopyPrompt,
                    text: text,
                    urlService: urlService
                )
            }
            
            Text("•")
                .foregroundColor(.gray)
            
            Button(action: onNewEntry) {
                Text("New Entry")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundColor(isHoveringNewEntry ? textHoverColor : textColor)
            .onHover { hovering in
                isHoveringNewEntry = hovering
                onBottomNavHover(hovering)
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            Text("•")
                .foregroundColor(.gray)
            
            Button(action: {
                preferencesService.toggleColorScheme()
            }) {
                Image(systemName: colorScheme == .light ? "moon.fill" : "sun.max.fill")
                    .foregroundColor(isHoveringThemeToggle ? textHoverColor : textColor)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHoveringThemeToggle = hovering
                onBottomNavHover(hovering)
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            Text("•")
                .foregroundColor(.gray)
            
            Button(action: {
                if speechService.isRecording {
                    speechService.stopDictation()
                } else {
                    speechService.startDictation(currentText: text)
                }
            }) {
                Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                    .foregroundColor(speechService.isRecording ? .red : (isHoveringDictation ? textHoverColor : textColor))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHoveringDictation = hovering
                onBottomNavHover(hovering)
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            Text("•")
                .foregroundColor(.gray)
            
            Button(action: {
                appState.switchToReflectionSelection()
            }) {
                Text("Reflect")
                    .font(.system(size: 13))
                    .foregroundColor(isHoveringReflect ? textHoverColor : textColor)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHoveringReflect = hovering
                onBottomNavHover(hovering)
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            Text("•")
                .foregroundColor(.gray)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingSidebar.toggle()
                }
            }) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(isHoveringClock ? textHoverColor : textColor)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHoveringClock = hovering
                onBottomNavHover(hovering)
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(8)
        .cornerRadius(6)
        .onHover { hovering in
            onBottomNavHover(hovering)
        }
    }
} 