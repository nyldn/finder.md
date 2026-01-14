import Foundation

/// Available templates for new markdown files
enum MarkdownTemplate: String, Codable, CaseIterable, Identifiable {
    case empty = "empty"
    case basicNote = "basicNote"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .empty:
            return "Empty"
        case .basicNote:
            return "Basic Note"
        }
    }
    
    var description: String {
        switch self {
        case .empty:
            return "A blank markdown file"
        case .basicNote:
            return "Note with title and date header"
        }
    }
    
    /// Generate content for the template
    /// - Parameter filename: The name of the file (used for title in some templates)
    /// - Returns: The template content as a string
    func content(filename: String) -> String {
        switch self {
        case .empty:
            return ""
            
        case .basicNote:
            // Extract title from filename (remove .md extension)
            let title = filename
                .replacingOccurrences(of: ".md", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
            
            // Format current date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .none
            let dateString = dateFormatter.string(from: Date())
            
            return """
            # \(title)
            
            Date: \(dateString)
            
            
            """
        }
    }
}
