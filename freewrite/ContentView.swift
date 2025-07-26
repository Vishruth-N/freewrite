// Swift 5.0
//
//  ContentView.swift
//  freewrite
//
//  Created by thorfinn on 2/14/25.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
import Speech
import AVFoundation
import AVKit

struct HumanEntry: Identifiable {
    let id: UUID
    let date: String
    let filename: String
    var previewText: String
    
    static func createNew() -> HumanEntry {
        let id = UUID()
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let dateString = dateFormatter.string(from: now)
        
        // For display
        dateFormatter.dateFormat = "MMM d"
        let displayDate = dateFormatter.string(from: now)
        
        return HumanEntry(
            id: id,
            date: displayDate,
            filename: "[\(id)]-[\(dateString)].md",
            previewText: ""
        )
    }
}

struct HeartEmoji: Identifiable {
    let id = UUID()
    var position: CGPoint
    var offset: CGFloat = 0
}

struct ContentView: View {
    private let headerString = "\n\n"
    @State private var entries: [HumanEntry] = []
    @State private var text: String = ""  // Remove initial welcome text since we'll handle it in createNewEntry
    
    @State private var selectedFont: String = "Arial"
    @State private var currentRandomFont: String = ""
    @State private var timeRemaining: Int = 900  // Changed to 900 seconds (15 minutes)
    @State private var timerIsRunning = false
    @State private var isHoveringTimer = false
    @State private var hoveredFont: String? = nil
    @State private var isHoveringSize = false
    @State private var fontSize: CGFloat = 18
    @State private var blinkCount = 0
    @State private var isBlinking = false
    @State private var opacity: Double = 1.0
    @State private var shouldShowGray = true // New state to control color
    @State private var lastClickTime: Date? = nil
    @State private var bottomNavOpacity: Double = 1.0
    @State private var isHoveringBottomNav = false
    @State private var selectedEntryIndex: Int = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedEntryId: UUID? = nil
    @State private var hoveredEntryId: UUID? = nil
    @State private var isHoveringChat = false  // Add this state variable
    @State private var showingChatMenu = false
    @State private var chatMenuAnchor: CGPoint = .zero
    @State private var showingSidebar = false  // Add this state variable
    @State private var hoveredTrashId: UUID? = nil
    @State private var hoveredExportId: UUID? = nil
    @State private var placeholderText: String = ""  // Add this line
    @State private var isHoveringNewEntry = false
    @State private var isHoveringClock = false
    @State private var isHoveringHistory = false
    @State private var isHoveringHistoryText = false
    @State private var isHoveringHistoryPath = false
    @State private var isHoveringHistoryArrow = false
    @State private var colorScheme: ColorScheme = .light // Add state for color scheme
    @State private var isHoveringThemeToggle = false // Add state for theme toggle hover
    @State private var didCopyPrompt: Bool = false // Add state for copy prompt feedback
    @State private var lastTypingTime: Date? = nil // Track when user last typed
    @State private var typingTimer: Timer? = nil // Timer to detect when typing stops
    @State private var timerZoomScale: CGFloat = 1.0 // Add zoom scale for timer
    
    // Dictation state variables
    @State private var isRecording = false
    @State private var isHoveringDictation = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    @State private var baseTextBeforeDictation = ""
    @State private var currentPartialText = ""
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let entryHeight: CGFloat = 40
    
    let availableFonts = NSFontManager.shared.availableFontFamilies
    let standardFonts = ["Arial", "Times New Roman"]
    let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26]
    let placeholderOptions = [
        "Begin writing",
        "Pick a thought and go",
        "Start typing",
        "What's on your mind",
        "Just start",
        "Type your first thought",
        "Start with one sentence",
        "Just say it"
    ]
    
    // Add file manager and save timer
    private let fileManager = FileManager.default
    private let saveTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    // Add cached documents directory
    private let documentsDirectory: URL = {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Freewrite")
        
        // Create Freewrite directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                // Directory creation failed, but we'll continue
            }
        }
        
        return directory
    }()
    
    // Add shared prompt constant
    private let aiChatPrompt = """
    below is my journal entry. wyt? talk through it with me like a friend. don't therpaize me and give me a whole breakdown, don't repeat my thoughts with headings. really take all of this, and tell me back stuff truly as if you're an old homie.
    
    Keep it casual, dont say yo, help me make new connections i don't see, comfort, validate, challenge, all of it. dont be afraid to say a lot. format with markdown headings if needed.

    do not just go through every single thing i say, and say it back to me. you need to proccess everythikng is say, make connections i don't see it, and deliver it all back to me as a story that makes me feel what you think i wanna feel. thats what the best therapists do.

    ideally, you're style/tone should sound like the user themselves. it's as if the user is hearing their own tone but it should still feel different, because you have different things to say and don't just repeat back they say.

    else, start by saying, "hey, thanks for showing me this. my thoughts:"
        
    my entry:
    """
    
    private let claudePrompt = """
    Take a look at my journal entry below. I'd like you to analyze it and respond with deep insight that feels personal, not clinical.
    Imagine you're not just a friend, but a mentor who truly gets both my tech background and my psychological patterns. I want you to uncover the deeper meaning and emotional undercurrents behind my scattered thoughts.
    Keep it casual, dont say yo, help me make new connections i don't see, comfort, validate, challenge, all of it. dont be afraid to say a lot. format with markdown headings if needed.
    Use vivid metaphors and powerful imagery to help me see what I'm really building. Organize your thoughts with meaningful headings that create a narrative journey through my ideas.
    Don't just validate my thoughts - reframe them in a way that shows me what I'm really seeking beneath the surface. Go beyond the product concepts to the emotional core of what I'm trying to solve.
    Be willing to be profound and philosophical without sounding like you're giving therapy. I want someone who can see the patterns I can't see myself and articulate them in a way that feels like an epiphany.
    Start with 'hey, thanks for showing me this. my thoughts:' and then use markdown headings to structure your response.

    Here's my journal entry:
    """
    
    // Initialize with saved theme preference if available
    init() {
        // Load saved color scheme preference
        let savedScheme = UserDefaults.standard.string(forKey: "colorScheme") ?? "light"
        _colorScheme = State(initialValue: savedScheme == "dark" ? .dark : .light)
    }
    
    // Modify getDocumentsDirectory to use cached value
    private func getDocumentsDirectory() -> URL {
        return documentsDirectory
    }
    
    // Add function to save text
    private func saveText() {
        let documentsDirectory = getDocumentsDirectory()
        let fileURL = documentsDirectory.appendingPathComponent("entry.md")
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            // File save failed - could show user notification here if needed
        }
    }
    
    // Add function to load text
    private func loadText() {
        let documentsDirectory = getDocumentsDirectory()
        let fileURL = documentsDirectory.appendingPathComponent("entry.md")
        
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                text = try String(contentsOf: fileURL, encoding: .utf8)
            }
        } catch {
            // File load failed - will use empty text
        }
    }
    
    // Add function to load existing entries
    private func loadExistingEntries() {
        let documentsDirectory = getDocumentsDirectory()
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            let mdFiles = fileURLs.filter { $0.pathExtension == "md" }
            
            // Process each file
            let entriesWithDates = mdFiles.compactMap { fileURL -> (entry: HumanEntry, date: Date, content: String)? in
                let filename = fileURL.lastPathComponent
                
                // Extract UUID and date from filename - pattern [uuid]-[yyyy-MM-dd-HH-mm-ss].md
                guard let uuidMatch = filename.range(of: "\\[(.*?)\\]", options: .regularExpression),
                      let dateMatch = filename.range(of: "\\[(\\d{4}-\\d{2}-\\d{2}-\\d{2}-\\d{2}-\\d{2})\\]", options: .regularExpression),
                      let uuid = UUID(uuidString: String(filename[uuidMatch].dropFirst().dropLast())) else {
                    return nil
                }
                
                // Parse the date string
                let dateString = String(filename[dateMatch].dropFirst().dropLast())
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
                
                guard let fileDate = dateFormatter.date(from: dateString) else {
                    return nil
                }
                
                // Read file contents for preview
                do {
                    let content = try String(contentsOf: fileURL, encoding: .utf8)
                    let preview = content
                        .replacingOccurrences(of: "\n", with: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let truncated = preview.isEmpty ? "" : (preview.count > 30 ? String(preview.prefix(30)) + "..." : preview)
                    
                    // Format display date
                    dateFormatter.dateFormat = "MMM d"
                    let displayDate = dateFormatter.string(from: fileDate)
                    
                    return (
                        entry: HumanEntry(
                            id: uuid,
                            date: displayDate,
                            filename: filename,
                            previewText: truncated
                        ),
                        date: fileDate,
                        content: content  // Store the full content to check for welcome message
                    )
                } catch {
                    return nil
                }
            }
            
            // Sort and extract entries
            entries = entriesWithDates
                .sorted { $0.date > $1.date }  // Sort by actual date from filename
                .map { $0.entry }
            
            // Successfully loaded and sorted entries
            
            // Check if we need to create a new entry
            let calendar = Calendar.current
            let today = Date()
            let todayStart = calendar.startOfDay(for: today)
            
            // Check if there's an empty entry from today
            let hasEmptyEntryToday = entries.contains { entry in
                // Convert the display date (e.g. "Mar 14") to a Date object
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d"
                if let entryDate = dateFormatter.date(from: entry.date) {
                    // Set year component to current year since our stored dates don't include year
                    var components = calendar.dateComponents([.year, .month, .day], from: entryDate)
                    components.year = calendar.component(.year, from: today)
                    
                    // Get start of day for the entry date
                    if let entryDateWithYear = calendar.date(from: components) {
                        let entryDayStart = calendar.startOfDay(for: entryDateWithYear)
                        return calendar.isDate(entryDayStart, inSameDayAs: todayStart) && entry.previewText.isEmpty
                    }
                }
                return false
            }
            
            // Check if we have only one entry and it's the welcome message
            let hasOnlyWelcomeEntry = entries.count == 1 && entriesWithDates.first?.content.contains("Welcome to Freewrite.") == true
            
            if entries.isEmpty {
                // First time user - create entry with welcome message
                // First time user - creating welcome entry
                createNewEntry()
            } else if !hasEmptyEntryToday && !hasOnlyWelcomeEntry {
                // No empty entry for today and not just the welcome entry - create new entry
                // No empty entry for today - creating new entry
                createNewEntry()
            } else {
                // Select the most recent empty entry from today or the welcome entry
                if let todayEntry = entries.first(where: { entry in
                    // Convert the display date (e.g. "Mar 14") to a Date object
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMM d"
                    if let entryDate = dateFormatter.date(from: entry.date) {
                        // Set year component to current year since our stored dates don't include year
                        var components = calendar.dateComponents([.year, .month, .day], from: entryDate)
                        components.year = calendar.component(.year, from: today)
                        
                        // Get start of day for the entry date
                        if let entryDateWithYear = calendar.date(from: components) {
                            let entryDayStart = calendar.startOfDay(for: entryDateWithYear)
                            return calendar.isDate(entryDayStart, inSameDayAs: todayStart) && entry.previewText.isEmpty
                        }
                    }
                    return false
                }) {
                    selectedEntryId = todayEntry.id
                    loadEntry(entry: todayEntry)
                } else if hasOnlyWelcomeEntry {
                    // If we only have the welcome entry, select it
                    selectedEntryId = entries[0].id
                    loadEntry(entry: entries[0])
                }
            }
            
        } catch {
            // Error loading directory contents - creating default entry
            createNewEntry()
        }
    }
    
    var randomButtonTitle: String {
        return currentRandomFont.isEmpty ? "Random" : "Random [\(currentRandomFont)]"
    }
    
    var timerButtonTitle: String {
        if !timerIsRunning && timeRemaining == 900 {
            return "15:00"
        }
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var timerColor: Color {
        if timerIsRunning {
            return isHoveringTimer ? (colorScheme == .light ? .black : .white) : .gray.opacity(0.8)
        } else {
            return isHoveringTimer ? (colorScheme == .light ? .black : .white) : (colorScheme == .light ? .gray : .gray.opacity(0.8))
        }
    }
    
    var lineHeight: CGFloat {
        // Use a simple multiplier for consistent line spacing (reduced for shorter cursor)
        return fontSize * 0.3
    }
    
    var fontSizeButtonTitle: String {
        return "\(Int(fontSize))px"
    }
    
    var placeholderOffset: CGFloat {
        // Instead of using calculated line height, use a simple offset
        return fontSize / 2
    }
    
    // Add a color utility computed property
    var popoverBackgroundColor: Color {
        return colorScheme == .light ? Color(NSColor.controlBackgroundColor) : Color(NSColor.darkGray)
    }
    
    var popoverTextColor: Color {
        return colorScheme == .light ? Color.primary : Color.white
    }
    
    @State private var viewHeight: CGFloat = 0
    
    // Computed properties to break down complex expressions
    private var textColor: Color {
        colorScheme == .light ? Color.gray : Color.gray.opacity(0.8)
    }
    
    private var textHoverColor: Color {
        colorScheme == .light ? Color.black : Color.white
    }
    
    private var backgroundColor: Color {
        colorScheme == .light ? Color(red: 0.992, green: 0.992, blue: 0.992) : Color(red: 0.08, green: 0.08, blue: 0.08)
    }
    
    private var textEditorForegroundColor: Color {
        colorScheme == .light ? Color(red: 0.165, green: 0.165, blue: 0.165) : Color(red: 0.9, green: 0.9, blue: 0.9)
    }
    
    private var placeholderColor: Color {
        colorScheme == .light ? .gray.opacity(0.5) : .gray.opacity(0.6)
    }
    
    // Main text editor view
    private var textEditorView: some View {
        TextEditor(text: $text)
            .background(backgroundColor)
            .font(.custom(selectedFont, size: fontSize))
            .foregroundColor(textEditorForegroundColor)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.never)
            .lineSpacing(lineHeight)
            .frame(maxWidth: 650)
            .padding(.leading, 5)
            .padding(.top, 40)
            .id("\(selectedFont)-\(fontSize)")
            .padding(.bottom, bottomNavOpacity > 0 ? 68 : 0)
            .ignoresSafeArea()
            .colorScheme(colorScheme)
            .tint(cursorColor)
            .onAppear {
                placeholderText = placeholderOptions.randomElement() ?? "Begin writing"
            }
            .overlay(placeholderOverlay, alignment: .topLeading)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                viewHeight = height
            }
            .contentMargins(.bottom, viewHeight / 4)
            .onChange(of: text) { oldValue, newValue in
                handleTextChange()
            }
    }
    
    // Placeholder overlay
    private var placeholderOverlay: some View {
        ZStack(alignment: .topLeading) {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholderText)
                    .font(.custom(selectedFont, size: fontSize))
                    .foregroundColor(placeholderColor)
                    .allowsHitTesting(false)
                    .padding(.leading, 10)
                    .padding(.top, 40)
            }
        }
    }
    
    // Font buttons section
    private var fontButtonsSection: some View {
        HStack(spacing: 8) {
            Button(fontSizeButtonTitle) {
                if let currentIndex = fontSizes.firstIndex(of: fontSize) {
                    let nextIndex = (currentIndex + 1) % fontSizes.count
                    fontSize = fontSizes[nextIndex]
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(isHoveringSize ? textHoverColor : textColor)
            .onHover { hovering in
                isHoveringSize = hovering
                isHoveringBottomNav = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            Text("•")
                .foregroundColor(.gray)
            
            Button("Arial") {
                selectedFont = "Arial"
                currentRandomFont = ""
            }
            .buttonStyle(.plain)
            .foregroundColor(hoveredFont == "Arial" ? textHoverColor : textColor)
            .onHover { hovering in
                hoveredFont = hovering ? "Arial" : nil
                isHoveringBottomNav = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            Text("•")
                .foregroundColor(.gray)
            
            Button("Serif") {
                selectedFont = "Times New Roman"
                currentRandomFont = ""
            }
            .buttonStyle(.plain)
            .foregroundColor(hoveredFont == "Serif" ? textHoverColor : textColor)
            .onHover { hovering in
                hoveredFont = hovering ? "Serif" : nil
                isHoveringBottomNav = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            Text("•")
                .foregroundColor(.gray)
            
            Button(randomButtonTitle) {
                if let randomFont = availableFonts.randomElement() {
                    selectedFont = randomFont
                    currentRandomFont = randomFont
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(hoveredFont == "Random" ? textHoverColor : textColor)
            .onHover { hovering in
                hoveredFont = hovering ? "Random" : nil
                isHoveringBottomNav = hovering
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
            isHoveringBottomNav = hovering
        }
    }
    
    // Utility buttons section
    private var utilityButtonsSection: some View {
        HStack(spacing: 8) {
            Button(timerButtonTitle) {
                let now = Date()
                if let lastClick = lastClickTime,
                   now.timeIntervalSince(lastClick) < 0.3 {
                    timeRemaining = 900
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
                isHoveringTimer = hovering
                isHoveringBottomNav = hovering
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
                NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                    if isHoveringTimer {
                        let scrollBuffer = event.deltaY * 0.25
                        
                        if abs(scrollBuffer) >= 0.1 {
                            let currentMinutes = timeRemaining / 60
                            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                            let direction = -scrollBuffer > 0 ? 2 : -2
                            let newMinutes = currentMinutes + direction
                            let roundedMinutes = (newMinutes / 2) * 2
                            let newTime = roundedMinutes * 60
                            timeRemaining = min(max(newTime, 0), 2700)
                            
                            // Add zoom pulse effect when scrolling
                            withAnimation(.easeInOut(duration: 0.15)) {
                                timerZoomScale = 1.2
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    timerZoomScale = isHoveringTimer ? 1.1 : 1.0
                                }
                            }
                        }
                    }
                    return event
                }
                
                // Keyboard event monitoring for backspace is now enabled
                
                // Add keyboard event monitoring for ESC key to exit fullscreen
                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if event.keyCode == 53 { // 53 is the key code for ESC
                        if let window = NSApplication.shared.windows.first {
                            if window.styleMask.contains(.fullScreen) {
                                window.toggleFullScreen(nil)
                            }
                        }
                        return nil // Consume the ESC event
                    }
                    return event
                }
            }
            
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
                isHoveringBottomNav = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .popover(isPresented: $showingChatMenu, attachmentAnchor: .point(UnitPoint(x: 0.5, y: 0)), arrowEdge: .top) {
                VStack(spacing: 0) {
                    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let gptFullText = aiChatPrompt + "\n\n" + trimmedText
                    let claudeFullText = claudePrompt + "\n\n" + trimmedText
                    let encodedGptText = gptFullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    let encodedClaudeText = claudeFullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    
                    let gptUrlLength = "https://chat.openai.com/?m=".count + encodedGptText.count
                    let claudeUrlLength = "https://claude.ai/new?q=".count + encodedClaudeText.count
                    let isUrlTooLong = gptUrlLength > 6000 || claudeUrlLength > 6000
                    
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
                            copyPromptToClipboard()
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
                            openChatGPT()
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
                            openClaude()
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
                            copyPromptToClipboard()
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
            
            Text("•")
                .foregroundColor(.gray)
            
            Button(action: {
                createNewEntry()
            }) {
                Text("New Entry")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundColor(isHoveringNewEntry ? textHoverColor : textColor)
            .onHover { hovering in
                isHoveringNewEntry = hovering
                isHoveringBottomNav = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            Text("•")
                .foregroundColor(.gray)
            
            Button(action: {
                colorScheme = colorScheme == .light ? .dark : .light
                UserDefaults.standard.set(colorScheme == .light ? "light" : "dark", forKey: "colorScheme")
            }) {
                Image(systemName: colorScheme == .light ? "moon.fill" : "sun.max.fill")
                    .foregroundColor(isHoveringThemeToggle ? textHoverColor : textColor)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHoveringThemeToggle = hovering
                isHoveringBottomNav = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            Text("•")
                .foregroundColor(.gray)
            
            Button(action: {
                if isRecording {
                    stopDictation()
                } else {
                    startDictation()
                }
            }) {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .foregroundColor(isRecording ? .red : (isHoveringDictation ? textHoverColor : textColor))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHoveringDictation = hovering
                isHoveringBottomNav = hovering
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
                isHoveringBottomNav = hovering
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
            isHoveringBottomNav = hovering
        }
    }
    
    // Bottom navigation view
    private var bottomNavigationView: some View {
        VStack {
            Spacer()
            HStack {
                fontButtonsSection
                Spacer()
                utilityButtonsSection
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Main content
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                textEditorView
                    
                
                bottomNavigationView
            }
            .padding()
            .background(backgroundColor)
            .opacity(bottomNavOpacity)
            .onHover { hovering in
                isHoveringBottomNav = hovering
                if hovering {
                    withAnimation(.easeOut(duration: 0.2)) {
                        bottomNavOpacity = 1.0
                    }
                } else if timerIsRunning {
                    withAnimation(.easeIn(duration: 1.0)) {
                        bottomNavOpacity = 0.0
                    }
                }
            }
            
            // Right sidebar
            if showingSidebar {
                Divider()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notes")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            Text("\(entries.count) notes")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: getDocumentsDirectory().path)
                        }) {
                            Image(systemName: "folder")
                                .font(.system(size: 16))
                                .foregroundColor(isHoveringHistory ? .primary : .secondary)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            isHoveringHistory = hovering
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    
                    Divider()
                    
                    // Entries List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(entries) { entry in
                                Button(action: {
                                    if selectedEntryId != entry.id {
                                        // Save current entry before switching
                                        if let currentId = selectedEntryId,
                                           let currentEntry = entries.first(where: { $0.id == currentId }) {
                                            saveEntry(entry: currentEntry)
                                        }
                                        
                                        selectedEntryId = entry.id
                                        loadEntry(entry: entry)
                                    }
                                }) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text(entry.previewText.isEmpty ? "New Note" : entry.previewText)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .lineLimit(1)
                                                    .foregroundColor(entry.id == selectedEntryId ? 
                                                        (colorScheme == .dark ? .black : .primary) : .primary)
                                                
                                                Spacer()
                                                
                                                // Trash icon that appears on hover
                                                if hoveredEntryId == entry.id {
                                                    Button(action: {
                                                        deleteEntry(entry: entry)
                                                    }) {
                                                        Image(systemName: "trash")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(hoveredTrashId == entry.id ? .red : .secondary)
                                                    }
                                                    .buttonStyle(.plain)
                                                    .onHover { hovering in
                                                        withAnimation(.easeInOut(duration: 0.2)) {
                                                            hoveredTrashId = hovering ? entry.id : nil
                                                        }
                                                        if hovering {
                                                            NSCursor.pointingHand.push()
                                                        } else {
                                                            NSCursor.pop()
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            Text(entry.date)
                                                .font(.system(size: 13))
                                                .foregroundColor(entry.id == selectedEntryId && colorScheme == .dark ? 
                                                    .black.opacity(0.7) : .secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        Rectangle()
                                            .fill(backgroundColor(for: entry))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contentShape(Rectangle())
                                .onHover { hovering in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        hoveredEntryId = hovering ? entry.id : nil
                                    }
                                }
                                .onAppear {
                                    NSCursor.pop()  // Reset cursor when button appears
                                }
                                .help("Click to select this entry")  // Add tooltip
                                
                                if entry.id != entries.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .scrollIndicators(.never)
                }
                .frame(width: 300)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .frame(minWidth: 1100, minHeight: 600)
        .animation(.easeInOut(duration: 0.2), value: showingSidebar)
        .preferredColorScheme(colorScheme)
        .onAppear {
            showingSidebar = false  // Hide sidebar by default
            loadExistingEntries()
        }
        .onChange(of: text) { _ in
            // Save current entry when text changes
            if let currentId = selectedEntryId,
               let currentEntry = entries.first(where: { $0.id == currentId }) {
                saveEntry(entry: currentEntry)
            }
        }
        .onReceive(timer) { _ in
            if timerIsRunning && timeRemaining > 0 {
                timeRemaining -= 1
            } else if timeRemaining == 0 {
                timerIsRunning = false
                if !isHoveringBottomNav {
                    withAnimation(.easeOut(duration: 1.0)) {
                        bottomNavOpacity = 1.0
                    }
                }
            }
        }

    }
    
    private var cursorColor: Color {
        colorScheme == .light ? Color(red: 0.078, green: 0.502, blue: 0.969) : Color(red: 1.0, green: 0.871, blue: 0.408)
    }
    
    private func backgroundColor(for entry: HumanEntry) -> Color {
        if entry.id == selectedEntryId {
            if colorScheme == .dark {
                return Color(red: 1.0, green: 0.871, blue: 0.408).opacity(0.7) // #FFDE68 selection for dark mode
            } else {
                return Color(red: 0.545, green: 0.761, blue: 1.0) // #8BC2FF selection for light mode
            }
        } else if entry.id == hoveredEntryId {
            if colorScheme == .dark {
                return Color.white.opacity(0.05)
            } else {
                return Color.black.opacity(0.05)
            }
        } else {
            return Color.clear
        }
    }
    
    private func updatePreviewText(for entry: HumanEntry) {
        let documentsDirectory = getDocumentsDirectory()
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let preview = content
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let truncated = preview.isEmpty ? "" : (preview.count > 30 ? String(preview.prefix(30)) + "..." : preview)
            
            // Find and update the entry in the entries array
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index].previewText = truncated
            }
        } catch {
            // Error updating preview text
        }
    }
    
    private func saveEntry(entry: HumanEntry) {
        let documentsDirectory = getDocumentsDirectory()
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            // Successfully saved entry
            updatePreviewText(for: entry)  // Update preview after saving
        } catch {
            // Error saving entry
        }
    }
    
    private func loadEntry(entry: HumanEntry) {
        let documentsDirectory = getDocumentsDirectory()
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
        
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                text = try String(contentsOf: fileURL, encoding: .utf8)
                // Successfully loaded entry
            }
        } catch {
            // Error loading entry
        }
    }
    
    private func createNewEntry() {
        let newEntry = HumanEntry.createNew()
        entries.insert(newEntry, at: 0) // Add to the beginning
        selectedEntryId = newEntry.id
        
        // If this is the first entry (entries was empty before adding this one)
        if entries.count == 1 {
            // Read welcome message from default.md
            if let defaultMessageURL = Bundle.main.url(forResource: "default", withExtension: "md"),
               let defaultMessage = try? String(contentsOf: defaultMessageURL, encoding: .utf8) {
                text = "\n\n" + defaultMessage
            }
            // Save the welcome message immediately
            saveEntry(entry: newEntry)
            // Update the preview text
            updatePreviewText(for: newEntry)
        } else {
            // Regular new entry starts with newlines
            text = ""
            // Randomize placeholder text for new entry
            placeholderText = placeholderOptions.randomElement() ?? "Begin writing"
            // Save the empty entry
            saveEntry(entry: newEntry)
        }
    }
    
    private func openChatGPT() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullText = aiChatPrompt + "\n\n" + trimmedText
        
        if let encodedText = fullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://chat.openai.com/?m=" + encodedText) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openClaude() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullText = claudePrompt + "\n\n" + trimmedText
        
        if let encodedText = fullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://claude.ai/new?q=" + encodedText) {
            NSWorkspace.shared.open(url)
        }
    }

    private func copyPromptToClipboard() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullText = aiChatPrompt + "\n\n" + trimmedText

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fullText, forType: .string)
        // Prompt copied to clipboard
    }
    
    private func handleTextChange() {
        let now = Date()
        lastTypingTime = now
        
        // Start timer if not already running and text is not empty
        if !timerIsRunning && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            timerIsRunning = true
        }
        
        // Cancel existing typing timer
        typingTimer?.invalidate()
        
        // Set new timer to stop after 3 seconds of inactivity
        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            // Stop timer if it's running
            if timerIsRunning {
                timerIsRunning = false
            }
        }
    }
    
    private func deleteEntry(entry: HumanEntry) {
        // Delete the file from the filesystem
        let documentsDirectory = getDocumentsDirectory()
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
        
        do {
            try fileManager.removeItem(at: fileURL)
            // Successfully deleted file
            
            // Remove the entry from the entries array
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries.remove(at: index)
                
                // If the deleted entry was selected, select the first entry or create a new one
                if selectedEntryId == entry.id {
                    if let firstEntry = entries.first {
                        selectedEntryId = firstEntry.id
                        loadEntry(entry: firstEntry)
                    } else {
                        createNewEntry()
                    }
                }
            }
        } catch {
            // Error deleting file
        }
    }
    
    // Extract a title from entry content for PDF export
    private func extractTitleFromContent(_ content: String, date: String) -> String {
        // Clean up content by removing leading/trailing whitespace and newlines
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If content is empty, just use the date
        if trimmedContent.isEmpty {
            return "Entry \(date)"
        }
        
        // Split content into words, ignoring newlines and removing punctuation
        let words = trimmedContent
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { word in
                word.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:\"'()[]{}<>"))
                    .lowercased()
            }
            .filter { !$0.isEmpty }
        
        // If we have at least 4 words, use them
        if words.count >= 4 {
            return "\(words[0])-\(words[1])-\(words[2])-\(words[3])"
        }
        
        // If we have fewer than 4 words, use what we have
        if !words.isEmpty {
            return words.joined(separator: "-")
        }
        
        // Fallback to date if no words found
        return "Entry \(date)"
    }
    
    private func exportEntryAsPDF(entry: HumanEntry) {
        // First make sure the current entry is saved
        if selectedEntryId == entry.id {
            saveEntry(entry: entry)
        }
        
        // Get entry content
        let documentsDirectory = getDocumentsDirectory()
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
        
        do {
            // Read the content of the entry
            let entryContent = try String(contentsOf: fileURL, encoding: .utf8)
            
            // Extract a title from the entry content and add .pdf extension
            let suggestedFilename = extractTitleFromContent(entryContent, date: entry.date) + ".pdf"
            
            // Create save panel
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType.pdf]
            savePanel.nameFieldStringValue = suggestedFilename
            savePanel.isExtensionHidden = false  // Make sure extension is visible
            
            // Show save dialog
            if savePanel.runModal() == .OK, let url = savePanel.url {
                // Create PDF data
                if let pdfData = createPDFFromText(text: entryContent) {
                    try pdfData.write(to: url)
                    // Successfully exported PDF
                }
            }
        } catch {
            // Error in PDF export
        }
    }
    
    private func createPDFFromText(text: String) -> Data? {
        // Letter size page dimensions
        let pageWidth: CGFloat = 612.0  // 8.5 x 72
        let pageHeight: CGFloat = 792.0 // 11 x 72
        let margin: CGFloat = 72.0      // 1-inch margins
        
        // Calculate content area
        let contentRect = CGRect(
            x: margin,
            y: margin,
            width: pageWidth - (margin * 2),
            height: pageHeight - (margin * 2)
        )
        
        // Create PDF data container
        let pdfData = NSMutableData()
        
        // Configure text formatting attributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineHeight
        
        let font = NSFont(name: selectedFont, size: fontSize) ?? .systemFont(ofSize: fontSize)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.0),
            .paragraphStyle: paragraphStyle
        ]
        
        // Trim the initial newlines before creating the PDF
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create the attributed string with formatting
        let attributedString = NSAttributedString(string: trimmedText, attributes: textAttributes)
        
        // Create a Core Text framesetter for text layout
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        
        // Create a PDF context with the data consumer
        guard let pdfContext = CGContext(consumer: CGDataConsumer(data: pdfData as CFMutableData)!, mediaBox: nil, nil) else {
            return nil
        }
        
        // Track position within text
        var currentRange = CFRange(location: 0, length: 0)
        var pageIndex = 0
        
        // Create a path for the text frame
        let framePath = CGMutablePath()
        framePath.addRect(contentRect)
        
        // Continue creating pages until all text is processed
        while currentRange.location < attributedString.length {
            // Begin a new PDF page
            pdfContext.beginPage(mediaBox: nil)
            
            // Fill the page with white background
            pdfContext.setFillColor(NSColor.white.cgColor)
            pdfContext.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
            
            // Create a frame for this page's text
            let frame = CTFramesetterCreateFrame(
                framesetter, 
                currentRange, 
                framePath, 
                nil
            )
            
            // Draw the text frame
            CTFrameDraw(frame, pdfContext)
            
            // Get the range of text that was actually displayed in this frame
            let visibleRange = CTFrameGetVisibleStringRange(frame)
            
            // Move to the next block of text for the next page
            currentRange.location += visibleRange.length
            
            // Finish the page
            pdfContext.endPage()
            pageIndex += 1
            
            // Safety check - don't allow infinite loops
            if pageIndex > 1000 {
                break
            }
        }
        
        // Finalize the PDF document
        pdfContext.closePDF()
        
        return pdfData as Data
    }
    
    // MARK: - Dictation Functions
    
    private func startDictation() {
        // Check if speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            return
        }
        
        // Request speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.startRecording()
                }
            }
        }
    }
    
    private func startRecording() {
        // Check if speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            return
        }
        
        // Request microphone permission first (macOS compatible)
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            proceedWithRecording()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.proceedWithRecording()
                    } else {
                        print("Microphone permission denied")
                    }
                }
            }
        case .denied, .restricted:
            print("Microphone permission denied")
        @unknown default:
            print("Unknown microphone permission status")
        }
    }
    
    private func proceedWithRecording() {
        // Check if speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            return
        }
        
        // Stop any existing recording
        if isRecording {
            stopRecording()
        }
        
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Get audio input node
        let inputNode = audioEngine.inputNode
        
        // Remove any existing tap
        inputNode.removeTap(onBus: 0)
        
        // Store the current text as base before starting dictation
        baseTextBeforeDictation = text
        
        // Create recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            DispatchQueue.main.async {
                // Don't process results if we're no longer recording
                guard self.isRecording else { return }
                
                if let result = result {
                    // Get the transcribed text
                    let transcribedText = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        // For final results, append to base text permanently
                        self.text = self.baseTextBeforeDictation + transcribedText + " "
                        self.currentPartialText = ""
                    } else {
                        // For partial results, show them temporarily
                        self.currentPartialText = transcribedText
                        self.text = self.baseTextBeforeDictation + transcribedText
                    }
                }
                
                if error != nil {
                    // Only call stopRecording if we're still recording to avoid recursion
                    if self.isRecording {
                        self.stopRecording()
                    }
                }
                
                if result?.isFinal == true {
                    self.stopRecording()
                }
            }
        }
        
        // Configure audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            stopRecording()
        }
    }
    
    private func stopDictation() {
        stopRecording()
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        
        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // Remove tap safely
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Clean up partial text state
        // Keep the current text as is - it already contains the transcribed content
        // Only add a space if we have transcribed content beyond the base text
        if text.count > baseTextBeforeDictation.count && !text.hasSuffix(" ") {
            text += " "
        }
        
        currentPartialText = ""
        baseTextBeforeDictation = ""
        
        isRecording = false
    }
}

// Helper function to calculate line height
func getLineHeight(font: NSFont) -> CGFloat {
    return font.ascender - font.descender + font.leading
}

// Add helper extension to find NSTextView
extension NSView {
    func findTextView() -> NSView? {
        if self is NSTextView {
            return self
        }
        for subview in subviews {
            if let textView = subview.findTextView() {
                return textView
            }
        }
        return nil
    }
}

// Add helper extension for finding subviews of a specific type
extension NSView {
    func findSubview<T: NSView>(ofType type: T.Type) -> T? {
        if let typedSelf = self as? T {
            return typedSelf
        }
        for subview in subviews {
            if let found = subview.findSubview(ofType: type) {
                return found
            }
        }
        return nil
    }
}

#Preview {
    ContentView()
}
