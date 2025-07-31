import SwiftUI

struct AppSettings {
    static let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26]
    static let standardFonts = ["Arial", "Times New Roman"]
    static let defaultTimerDuration = 900 // 15 minutes
    static let maxTimerDuration = 2700 // 45 minutes
    
    static let placeholderOptions = [
        "Begin writing",
        "Pick a thought and go",
        "Start typing",
        "What's on your mind",
        "Just start",
        "Type your first thought",
        "Start with one sentence",
        "Just say it"
    ]
    
    static let aiChatPrompt = """
    below is my journal entry. wyt? talk through it with me like a friend. don't therpaize me and give me a whole breakdown, don't repeat my thoughts with headings. really take all of this, and tell me back stuff truly as if you're an old homie.
    
    Keep it casual, dont say yo, help me make new connections i don't see, comfort, validate, challenge, all of it.

    do not just go through every single thing i say, and say it back to me. you need to proccess everythikng is say, make connections i don't see it, and deliver it all back to me as a story that makes me feel what you think i wanna feel. thats what the best therapists do.

    ideally, you're style/tone should sound like the user themselves. it's as if the user is hearing their own tone but it should still feel different, because you have different things to say and don't just repeat back they say.

    else, start by saying, "hey, thanks for sharing this with me, let me reflect on what you've written..."
        
    my entry:
    """
    
    static let claudePrompt = """
    Take a look at my journal entry below. I'd like you to analyze it and respond with deep insight that feels personal, not clinical.
    Imagine you're not just a friend, but a mentor who truly gets both my tech background and my psychological patterns. I want you to uncover the deeper meaning and emotional undercurrents behind my scattered thoughts.
    Keep it casual, dont say yo, help me make new connections i don't see, comfort, validate, challenge, all of it.
    Use vivid metaphors and powerful imagery to help me see what I'm really building. Organize your thoughts with meaningful headings that create a narrative journey through my ideas.
    Don't just validate my thoughts - reframe them in a way that shows me what I'm really seeking beneath the surface. Go beyond the product concepts to the emotional core of what I'm trying to solve.
    Be willing to be profound and philosophical without sounding like you're giving therapy. I want someone who can see the patterns I can't see myself and articulate them in a way that feels like an epiphany.
    Start with 'hey, thanks for sharing this with me, let me reflect on what you've written...'

    Here's my journal entry:
    """
}

enum AppMode {
    case writing
    case reflectionSelection
    case voiceAgent
}

@MainActor
class AppState: ObservableObject {
    @Published var currentMode: AppMode = .writing
    @Published var reflectionContext: String? = nil
    
    static let shared = AppState()
    
    private init() {}
    
    func switchToReflectionSelection() {
        currentMode = .reflectionSelection
    }
    
    func switchToVoiceAgent(with context: String? = nil) {
        reflectionContext = context
        currentMode = .voiceAgent
    }
    
    func switchToWriting() {
        currentMode = .writing
        reflectionContext = nil
    }
}

class PreferencesService: ObservableObject {
    @Published var colorScheme: ColorScheme
    
    init() {
        let savedScheme = UserDefaults.standard.string(forKey: "colorScheme") ?? "light"
        self.colorScheme = savedScheme == "dark" ? .dark : .light
    }
    
    func toggleColorScheme() {
        colorScheme = colorScheme == .light ? .dark : .light
        UserDefaults.standard.set(colorScheme == .light ? "light" : "dark", forKey: "colorScheme")
    }
} 