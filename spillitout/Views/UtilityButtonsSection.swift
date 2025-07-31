import SwiftUI

struct UtilityButtonsSection: View {
    @Binding var timeRemaining: Int
    @Binding var timerIsRunning: Bool
    @Binding var showingSidebar: Bool
    @ObservedObject var speechService: SpeechService
    @ObservedObject var preferencesService: PreferencesService
    @ObservedObject var backspaceService: BackspaceService
    let text: String
    let onNewEntry: () -> Void
    let onReflect: () -> Void
    let onBottomNavHover: (Bool) -> Void
    
    @State private var isHoveringNewEntry = false
    @State private var isHoveringThemeToggle = false
    @State private var isHoveringDictation = false
    @State private var isHoveringClock = false
    @State private var isHoveringReflect = false
    @State private var isHoveringBackspace = false
    @Environment(\.colorScheme) var colorScheme
    
    private var textColor: Color {
        colorScheme == .light ? Color.gray : Color.gray.opacity(0.8)
    }
    
    private var textHoverColor: Color {
        colorScheme == .light ? Color.black : Color.white
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: onReflect) {
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
            
            TimerButtonView(timeRemaining: $timeRemaining, timerIsRunning: $timerIsRunning)
            
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
                backspaceService.toggleBackspaceDisabled()
            }) {
                Image(systemName: backspaceService.isBackspaceDisabled ? "lock.fill" : "lock.open")
                    .foregroundColor(backspaceService.isBackspaceDisabled ? .orange : (isHoveringBackspace ? textHoverColor : textColor))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHoveringBackspace = hovering
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