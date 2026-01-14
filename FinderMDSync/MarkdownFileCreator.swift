import Foundation
import os.log

/// Errors that can occur during file creation
enum FileCreationError: LocalizedError {
    case invalidFilename(String)
    case folderNotWritable(URL)
    case creationFailed(Error)
    case securityScopeAccessDenied
    
    var errorDescription: String? {
        switch self {
        case .invalidFilename(let name):
            return "Invalid filename: \(name)"
        case .folderNotWritable(let url):
            return "Cannot write to folder: \(url.lastPathComponent). Check permissions."
        case .creationFailed(let error):
            return "Failed to create file: \(error.localizedDescription)"
        case .securityScopeAccessDenied:
            return "Permission denied. Please add this folder in FinderMD settings."
        }
    }
}

/// Handles the creation of markdown files
class MarkdownFileCreator {
    
    private let logger = Logger(subsystem: AppConstants.extensionBundleID, category: "FileCreator")
    private let fileManager = FileManager.default
    
    /// Characters not allowed in macOS filenames
    private let invalidCharacters = CharacterSet(charactersIn: ":/\\")
    
    /// Maximum filename length (macOS limit is 255 bytes for HFS+/APFS)
    private let maxFilenameLength = 200
    
    /// Creates a new markdown file
    /// - Parameters:
    ///   - folder: Target folder URL
    ///   - filename: Desired filename (with or without .md extension)
    ///   - template: Template to use for content
    ///   - conflictPolicy: How to handle existing files
    /// - Returns: URL of the created file
    /// - Throws: FileCreationError if creation fails
    func createFile(
        in folder: URL,
        filename: String,
        template: MarkdownTemplate,
        conflictPolicy: ConflictPolicy
    ) throws -> URL {
        // Validate and sanitize filename
        let sanitizedName = try sanitizeFilename(filename)
        
        // Ensure .md extension
        var finalName = sanitizedName
        if !finalName.lowercased().hasSuffix(".md") {
            finalName += ".md"
        }
        
        // Check folder writability
        guard fileManager.isWritableFile(atPath: folder.path) else {
            throw FileCreationError.folderNotWritable(folder)
        }
        
        // Resolve final path (handle conflicts)
        let finalURL = resolveConflicts(
            baseURL: folder.appendingPathComponent(finalName),
            policy: conflictPolicy
        )
        
        // Generate content from template
        let content = template.content(filename: finalURL.lastPathComponent)
        
        // Write file atomically
        do {
            try content.write(to: finalURL, atomically: true, encoding: .utf8)
            logger.info("Created file: \(finalURL.path)")
            return finalURL
        } catch {
            logger.error("File write failed: \(error.localizedDescription)")
            throw FileCreationError.creationFailed(error)
        }
    }
    
    /// Sanitizes a filename by removing invalid characters
    /// - Parameter name: Original filename
    /// - Returns: Sanitized filename
    /// - Throws: FileCreationError.invalidFilename if the result is empty or invalid
    private func sanitizeFilename(_ name: String) throws -> String {
        var sanitized = name.trimmingCharacters(in: .whitespaces)
        
        // Remove invalid characters
        sanitized = sanitized
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
        
        // Remove leading dots (hidden files)
        while sanitized.hasPrefix(".") {
            sanitized = String(sanitized.dropFirst())
        }
        
        // Remove trailing dots
        while sanitized.hasSuffix(".") && !sanitized.hasSuffix(".md") {
            sanitized = String(sanitized.dropLast())
        }
        
        // Truncate if too long
        if sanitized.count > maxFilenameLength {
            let endIndex = sanitized.index(sanitized.startIndex, offsetBy: maxFilenameLength)
            sanitized = String(sanitized[..<endIndex])
        }
        
        sanitized = sanitized.trimmingCharacters(in: .whitespaces)
        
        guard !sanitized.isEmpty else {
            throw FileCreationError.invalidFilename(name)
        }
        
        return sanitized
    }
    
    /// Resolves filename conflicts by adding suffixes
    /// - Parameters:
    ///   - baseURL: Original file URL
    ///   - policy: Conflict resolution policy
    /// - Returns: Final URL (possibly with suffix)
    private func resolveConflicts(baseURL: URL, policy: ConflictPolicy) -> URL {
        guard fileManager.fileExists(atPath: baseURL.path) else {
            return baseURL
        }
        
        // For auto-suffix policy, find next available number
        let folder = baseURL.deletingLastPathComponent()
        let ext = baseURL.pathExtension
        var baseName = baseURL.deletingPathExtension().lastPathComponent
        
        // Check if already has a suffix like " 2"
        let suffixPattern = #" \d+$"#
        if let range = baseName.range(of: suffixPattern, options: .regularExpression) {
            baseName = String(baseName[..<range.lowerBound])
        }
        
        var counter = 2
        var candidateURL: URL
        
        repeat {
            let newName = "\(baseName) \(counter).\(ext)"
            candidateURL = folder.appendingPathComponent(newName)
            counter += 1
        } while fileManager.fileExists(atPath: candidateURL.path) && counter < 1000
        
        return candidateURL
    }
}
