import SwiftUI

struct AppView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var chatViewModel = ChatViewModel()
    
    let initialContext: String?
    let appState: AppState?
    @State private var hasInitialized = false

    @State private var error: Error?
    @FocusState private var keyboardFocus: Bool

    @Namespace private var namespace
    
    init(initialContext: String? = nil, appState: AppState? = nil) {
        self.initialContext = initialContext
        self.appState = appState
    }

    var body: some View {
        ZStack(alignment: .top) {
            if viewModel.isInteractive {
                interactions()
            } else {
                connectingView()
            }

            errors()
        }
        .environment(\.namespace, namespace)
        #if os(visionOS)
            .ornament(attachmentAnchor: .scene(.bottom)) {
                if viewModel.isInteractive {
                    ControlBar(appState: appState)
                        .glassBackgroundEffect()
                }
            }
            .alert("warning.reconnecting", isPresented: .constant(viewModel.connectionState == .reconnecting)) {}
            .alert(error?.localizedDescription ?? "error.title", isPresented: .constant(error != nil)) {
                Button("error.ok") { error = nil }
            }
        #else
            .safeAreaInset(edge: .bottom) {
                if viewModel.isInteractive, !keyboardFocus {
                    ControlBar(appState: appState)
                        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                }
            }
        #endif
            .background(.bg1)
            .animation(.default, value: viewModel.isInteractive)
            .animation(.default, value: viewModel.interactionMode)
            .animation(.default, value: viewModel.isCameraEnabled)
            .animation(.default, value: viewModel.isScreenShareEnabled)
            .animation(.default, value: error?.localizedDescription)
            .onAppear {
                Dependencies.shared.errorHandler = { error = $0 }
                
                // Auto-connect when we have initial context (reflection mode)
                // or show normal start view for manual connection
                if !hasInitialized {
                    hasInitialized = true
                    if let context = initialContext {
                        // Auto-connect for reflection mode
                        Task {
                            await viewModel.connect()
                            await waitForConnection()
                            await chatViewModel.sendMessage(context)
                        }
                    }
                }
            }
            .onDisappear {
                // Clean up when view disappears to prevent memory leaks and stream errors
                Task {
                    await viewModel.disconnect()
                    chatViewModel.cleanup()
                }
            }
        #if os(iOS)
            .sensoryFeedback(.impact, trigger: viewModel.isListening)
        #endif
    }

    @ViewBuilder
    private func connectingView() -> some View {
        if initialContext != nil {
            // Reflection mode - show connecting state with animation
            VStack(spacing: 40) {
                // Animated bars with breathing effect
                HStack(spacing: 4) {
                    ForEach(0 ..< 5, id: \.self) { index in
                        Rectangle()
                            .fill(.fg0)
                            .frame(width: 4, height: barHeight(index))
                            .animation(
                                .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                                value: viewModel.connectionState == .connecting
                            )
                    }
                }
                .scaleEffect(viewModel.connectionState == .connecting ? 1.1 : 1.0)
                
                VStack(spacing: 16) {
                    Text(connectionStatusText)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.fg0)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.connectionState)
                    
                    Text("Preparing your reflection session")
                        .font(.body)
                        .foregroundStyle(.fg3)
                        .opacity(0.8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Fallback - should not happen with current flow
            VStack(spacing: 32) {
                Text("Initializing...")
                    .font(.title2)
                    .foregroundStyle(.fg0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var connectionStatusText: String {
        switch viewModel.connectionState {
        case .disconnected:
            return "Connecting to Voice Agent..."
        case .connecting:
            return "Establishing Connection..."
        case .connected:
            return "Connected!"
        case .reconnecting:
            return "Reconnecting..."
        }
    }
    
    private func barHeight(_ index: Int) -> CGFloat {
        let baseHeights: [CGFloat] = [16, 32, 48, 32, 16]
        let animationMultiplier = viewModel.connectionState == .connecting ? 1.5 : 1.0
        return baseHeights[index] * animationMultiplier
    }

    @ViewBuilder
    private func interactions() -> some View {
        #if os(visionOS)
        VisionInteractionView(keyboardFocus: $keyboardFocus)
            .environment(chatViewModel)
            .overlay(alignment: .bottom) {
                agentListening()
                    .padding(16 * .grid)
            }
        #else
        switch viewModel.interactionMode {
        case .text:
            TextInteractionView(keyboardFocus: $keyboardFocus)
                .environment(chatViewModel)
        case .voice:
            VoiceInteractionView()
                .overlay(alignment: .bottom) {
                    agentListening()
                        .padding()
                }
        }
        #endif
    }

    @ViewBuilder
    private func errors() -> some View {
        #if !os(visionOS)
        if case .reconnecting = viewModel.connectionState {
            WarningView(warning: "warning.reconnecting")
        }

        if let error {
            ErrorView(error: error) { self.error = nil }
        }
        #endif
    }

    @ViewBuilder
    private func agentListening() -> some View {
        ZStack {
            if chatViewModel.messages.isEmpty,
               !viewModel.isCameraEnabled,
               !viewModel.isScreenShareEnabled
            {
                AgentListeningView()
            }
        }
        .animation(.default, value: chatViewModel.messages.isEmpty)
    }
    
    private func waitForConnection() async {
        // Wait for the voice agent to be connected before sending initial message
        while viewModel.connectionState != .connected {
            try? await Task.sleep(for: .milliseconds(100))
        }
        // Additional small delay to ensure everything is ready
        try? await Task.sleep(for: .seconds(1))
    }
}

#Preview {
    AppView()
}
