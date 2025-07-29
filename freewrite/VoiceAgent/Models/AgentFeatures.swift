import Foundation

/// A set of flags that define the features supported by the agent.
/// Enable them based on your agent capabilities.
struct AgentFeatures: OptionSet {
    let rawValue: Int

    static let voice = Self(rawValue: 1 << 0)
    static let text = Self(rawValue: 1 << 1)
    static let video = Self(rawValue: 1 << 2)

    static let current: Self = [.voice, .text]
} 