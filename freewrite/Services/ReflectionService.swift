import Foundation

enum ReflectionTimeFrame {
    case thisSession
    case thisWeek  
    case thisMonth
    
    var displayName: String {
        switch self {
        case .thisSession:
            return "This Session"
        case .thisWeek:
            return "This Week"
        case .thisMonth:
            return "This Month"
        }
    }
}

class ReflectionService: ObservableObject {
    private let fileService: FileService
    
    init(fileService: FileService) {
        self.fileService = fileService
    }
    
    func buildReflectionContext(timeFrame: ReflectionTimeFrame, currentText: String) -> String {
        let entries = getEntriesForTimeFrame(timeFrame: timeFrame, currentText: currentText)
        let contextContent = entries.joined(separator: "\n\n---\n\n")
        
        // Use the existing reflection prompt template from AppSettings
        let basePrompt = AppSettings.claudePrompt
        
        return basePrompt + "\n" + contextContent
    }
    
    private func getEntriesForTimeFrame(timeFrame: ReflectionTimeFrame, currentText: String) -> [String] {
        switch timeFrame {
        case .thisSession:
            return getThisSessionEntries(currentText: currentText)
        case .thisWeek:
            return getThisWeekEntries()
        case .thisMonth:
            return getThisMonthEntries()
        }
    }
    
    private func getThisSessionEntries(currentText: String) -> [String] {
        // For "this session", we just return the current text being written
        let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? ["No content in current session."] : [trimmedText]
    }
    
    private func getThisWeekEntries() -> [String] {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        
        return getEntriesAfterDate(weekAgo)
    }
    
    private func getThisMonthEntries() -> [String] {
        let calendar = Calendar.current
        let now = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        return getEntriesAfterDate(monthAgo)
    }
    
    private func getEntriesAfterDate(_ cutoffDate: Date) -> [String] {
        let entries = fileService.loadExistingEntries()
        var results: [String] = []
        
        for entry in entries {
            // Extract date from filename - pattern [uuid]-[yyyy-MM-dd-HH-mm-ss].md
            if let dateString = extractDateFromFilename(entry.filename),
               let fileDate = parseFileDate(dateString),
               fileDate >= cutoffDate {
                
                if let content = fileService.loadEntry(entry: entry) {
                    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedContent.isEmpty {
                        // Add a header with the date for context
                        let displayDate = formatDisplayDate(fileDate)
                        results.append("**Entry from \(displayDate):**\n\(trimmedContent)")
                    }
                }
            }
        }
        
        return results.isEmpty ? ["No entries found for this time period."] : results
    }
    
    private func extractDateFromFilename(_ filename: String) -> String? {
        // Extract date from pattern [uuid]-[yyyy-MM-dd-HH-mm-ss].md
        let pattern = "\\[(\\d{4}-\\d{2}-\\d{2}-\\d{2}-\\d{2}-\\d{2})\\]"
        if let range = filename.range(of: pattern, options: .regularExpression) {
            let dateWithBrackets = String(filename[range])
            return String(dateWithBrackets.dropFirst().dropLast()) // Remove brackets
        }
        return nil
    }
    
    private func parseFileDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return dateFormatter.date(from: dateString)
    }
    
    private func formatDisplayDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
} 