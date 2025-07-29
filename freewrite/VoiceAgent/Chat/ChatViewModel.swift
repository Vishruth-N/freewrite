import AsyncAlgorithms
import Collections
import Foundation
import LiveKit
import Observation

/// A view model that aggregates messages from multiple message providers (senders and receivers)
/// and exposes a single entry point for the UI to interact with the message feed.
///
/// It does not expose any publicly mutable state, encouraging unidirectional data flow.
@MainActor
@Observable
final class ChatViewModel {
    // MARK: - Constants

    private enum Constants {
        static let throttle: Duration = .milliseconds(100)
    }

    // MARK: - State

    private(set) var messages: OrderedDictionary<ReceivedMessage.ID, ReceivedMessage> = [:]
    
    // MARK: - Background Tasks
    
    @ObservationIgnored
    private var messageObservationTasks: [Task<Void, Never>] = []
    @ObservationIgnored
    private var roomObservationTask: Task<Void, Never>?

    // MARK: - Dependencies

    @ObservationIgnored
    @Dependency(\.room) private var room
    @ObservationIgnored
    @Dependency(\.messageReceivers) private var messageReceivers
    @ObservationIgnored
    @Dependency(\.messageSenders) private var messageSenders
    @ObservationIgnored
    @Dependency(\.errorHandler) private var errorHandler

    // MARK: - Initialization

    init() {
        observeMessages()
        observeRoom()
    }
    
    deinit {
        // Note: Cannot call cleanup() here due to actor isolation
        // cleanup() is called explicitly in onDisappear where needed
    }

    // MARK: - Private

    private func observeMessages() {
        for messageReceiver in messageReceivers {
            let task = Task { [weak self] in
                do {
                    for await message in try await messageReceiver
                        .messages()
                        ._throttle(for: Constants.throttle)
                    {
                        guard let self else { return }
                        messages.updateValue(message, forKey: message.id)
                    }
                } catch {
                    self?.errorHandler(error)
                }
            }
            messageObservationTasks.append(task)
        }
    }

    private func observeRoom() {
        roomObservationTask = Task { [weak self] in
            guard let changes = self?.room.changes else { return }
            for await _ in changes {
                guard let self else { return }
                if room.connectionState == .disconnected {
                    clearHistory()
                }
            }
        }
    }

    private func clearHistory() {
        messages.removeAll()
    }
    
    /// Cleanup all background tasks
    public func cleanup() {
        messageObservationTasks.forEach { $0.cancel() }
        messageObservationTasks.removeAll()
        roomObservationTask?.cancel()
        roomObservationTask = nil
    }

    // MARK: - Actions

    func sendMessage(_ text: String) async {
        let message = SentMessage(id: UUID().uuidString, timestamp: Date(), content: .userText(text))
        do {
            for sender in messageSenders {
                try await sender.send(message)
            }
        } catch {
            errorHandler(error)
        }
    }
}
