import SwiftUI

struct TimerButtonView: View {
    @Binding var timeRemaining: Int
    @Binding var timerIsRunning: Bool
    @State private var isHovering = false
    @State private var lastClickTime: Date? = nil
    @State private var timerZoomScale: CGFloat = 1.0
    @Environment(\.colorScheme) var colorScheme
    
    private var timerButtonTitle: String {
        if !timerIsRunning && timeRemaining == AppSettings.defaultTimerDuration {
            return "15:00"
        }
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var timerColor: Color {
        if timerIsRunning {
            return isHovering ? (colorScheme == .light ? .black : .white) : .gray.opacity(0.8)
        } else {
            return isHovering ? (colorScheme == .light ? .black : .white) : (colorScheme == .light ? .gray : .gray.opacity(0.8))
        }
    }
    
    var body: some View {
        Button(timerButtonTitle) {
            let now = Date()
            if let lastClick = lastClickTime,
               now.timeIntervalSince(lastClick) < 0.3 {
                timeRemaining = AppSettings.defaultTimerDuration
                timerIsRunning = false
                lastClickTime = nil
            } else {
                timerIsRunning.toggle()
                lastClickTime = now
            }
        }
        .buttonStyle(.plain)
        .foregroundColor(timerColor)
        .scaleEffect(timerZoomScale)
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.pointingHand.push()
                withAnimation(.easeInOut(duration: 0.2)) {
                    timerZoomScale = 1.1
                }
            } else {
                NSCursor.pop()
                withAnimation(.easeInOut(duration: 0.2)) {
                    timerZoomScale = 1.0
                }
            }
        }
        .onAppear {
            setupScrollWheelMonitoring()
        }
    }
    
    private func setupScrollWheelMonitoring() {
        NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            if isHovering {
                let scrollBuffer = event.deltaY * 0.25
                
                if abs(scrollBuffer) >= 0.1 {
                    let currentMinutes = timeRemaining / 60
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                    let direction = -scrollBuffer > 0 ? 1 : -1
                    let newMinutes = currentMinutes + direction
                    let newTime = newMinutes * 60
                    timeRemaining = min(max(newTime, 0), AppSettings.maxTimerDuration)
                    
                    // Add zoom pulse effect when scrolling
                    withAnimation(.easeInOut(duration: 0.15)) {
                        timerZoomScale = 1.2
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            timerZoomScale = isHovering ? 1.1 : 1.0
                        }
                    }
                }
            }
            return event
        }
    }
} 