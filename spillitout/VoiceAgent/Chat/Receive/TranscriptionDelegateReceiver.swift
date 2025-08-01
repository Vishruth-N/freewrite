import Foundation
import LiveKit

/// An actor that receives transcription messages from the room and yields them as messages.
///
/// Room delegate methods are called multiple times for each message, with a stable message ID
/// that can be direcly used for diffing.
///
/// Example:
/// ```
/// { id: "1", content: "Hello" }
/// { id: "1", content: "Hello world!" }
/// ```
@available(*, deprecated, message: "Use TranscriptionStreamReceiver compatible with livekit-agents 1.0")
actor TranscriptionDelegateReceiver: MessageReceiver, RoomDelegate {
    private let room: Room
    private var continuation: AsyncStream<ReceivedMessage>.Continuation?

    init(room: Room) {
        self.room = room
        room.add(delegate: self)
    }

    deinit {
        room.remove(delegate: self)
    }

    /// Creates a new message stream for the transcription delegate receiver.
    func messages() -> AsyncStream<ReceivedMessage> {
        let (stream, continuation) = AsyncStream.makeStream(of: ReceivedMessage.self)
        self.continuation = continuation
        return stream
    }

    nonisolated func room(_: Room, participant: Participant, trackPublication _: TrackPublication, didReceiveTranscriptionSegments segments: [TranscriptionSegment]) {
        segments
            .filter { !$0.text.isEmpty }
            .forEach { segment in
                let message = ReceivedMessage(
                    id: segment.id,
                    timestamp: segment.lastReceivedTime,
                    content: participant.isAgent ? .agentTranscript(segment.text) : .userTranscript(segment.text)
                )
                Task {
                    await yield(message)
                }
            }
    }

    private func yield(_ message: ReceivedMessage) {
        continuation?.yield(message)
    }
}
