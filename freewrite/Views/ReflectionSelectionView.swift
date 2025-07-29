import SwiftUI

struct ReflectionSelectionView: View {
    @ObservedObject var appState: AppState
    let currentText: String
    let reflectionService: ReflectionService
    
    @Environment(\.colorScheme) var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .light ? Color.white : Color.black
    }
    
    private var buttonBackgroundColor: Color {
        colorScheme == .light ? Color.gray.opacity(0.1) : Color.white.opacity(0.1)
    }
    
    private var buttonHoverColor: Color {
        colorScheme == .light ? Color.gray.opacity(0.2) : Color.white.opacity(0.2)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Text("Reflect")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                    
                    Text("Choose what you'd like to reflect on")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 80)
                
                // Time period buttons
                VStack(spacing: 20) {
                    ReflectionTimeButton(
                        timeFrame: .thisSession,
                        onTap: { timeFrame in
                            startReflection(with: timeFrame)
                        }
                    )
                    
                    ReflectionTimeButton(
                        timeFrame: .thisWeek,
                        onTap: { timeFrame in
                            startReflection(with: timeFrame)
                        }
                    )
                    
                    ReflectionTimeButton(
                        timeFrame: .thisMonth,
                        onTap: { timeFrame in
                            startReflection(with: timeFrame)
                        }
                    )
                }
                .frame(maxWidth: 400)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Back button
            VStack {
                HStack {
                    Button(action: {
                        appState.switchToWriting()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back to Writing")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
            }
        }
    }
    
    private func startReflection(with timeFrame: ReflectionTimeFrame) {
        let context = reflectionService.buildReflectionContext(
            timeFrame: timeFrame,
            currentText: currentText
        )
        appState.switchToVoiceAgent(with: context)
    }
}

struct ReflectionTimeButton: View {
    let timeFrame: ReflectionTimeFrame
    let onTap: (ReflectionTimeFrame) -> Void
    
    @State private var isHovering = false
    @Environment(\.colorScheme) var colorScheme
    
    private var buttonBackgroundColor: Color {
        if isHovering {
            return colorScheme == .light ? Color.gray.opacity(0.2) : Color.white.opacity(0.2)
        } else {
            return colorScheme == .light ? Color.gray.opacity(0.1) : Color.white.opacity(0.1)
        }
    }
    
    private var description: String {
        switch timeFrame {
        case .thisSession:
            return "Reflect on what you're currently writing"
        case .thisWeek:
            return "Explore patterns and themes from the past week"
        case .thisMonth:
            return "Dive deep into your journey over the past month"
        }
    }
    
    var body: some View {
        Button(action: {
            onTap(timeFrame)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(timeFrame.displayName)
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(buttonBackgroundColor)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    ReflectionSelectionView(
        appState: AppState.shared,
        currentText: "Sample text for preview",
        reflectionService: ReflectionService(fileService: FileService())
    )
} 