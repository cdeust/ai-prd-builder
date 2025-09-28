import Foundation
import CommonModels

/// Intelligently detects and extracts mockup references from various input formats
public final class MockupInputDetector {

    /// Detected mockup input types
    public enum MockupSource {
        case filePath(String)
        case url(String)
        case base64Image(String)
        case temporaryFile(String)
        case clipboardReference(String)
    }

    /// Result of mockup detection
    public struct DetectionResult {
        public let textContent: String
        public let mockupSources: [MockupSource]
        public let guidelines: String?

        public var hasMockups: Bool {
            !mockupSources.isEmpty
        }
    }

    // MARK: - Detection Patterns

    private enum Patterns {
        // File path patterns
        static let absolutePath = #"^/[\w\-/. ]+\.(png|jpg|jpeg|gif|svg|pdf|sketch|fig|xd|ai|psd)$"#
        static let relativePath = #"^\.{0,2}/[\w\-/. ]+\.(png|jpg|jpeg|gif|svg|pdf|sketch|fig|xd|ai|psd)$"#
        static let homePath = #"^~[\w\-/. ]*\.(png|jpg|jpeg|gif|svg|pdf|sketch|fig|xd|ai|psd)$"#

        // URL patterns
        static let httpURL = #"^https?://[\w\-./]+\.(png|jpg|jpeg|gif|svg|pdf)(\?[\w=&]+)?$"#
        static let fileURL = #"^file://[\w\-/. ]+\.(png|jpg|jpeg|gif|svg|pdf|sketch|fig|xd|ai|psd)$"#

        // Base64 image pattern
        static let base64Image = #"^data:image/(png|jpeg|jpg|gif|svg\+xml);base64,[\w+/]+=*$"#

        // Terminal screenshot patterns (macOS)
        static let tempScreenshot = #"/var/folders/[\w/-]+/T/[\w]+/Screenshot[\w\-. ]*\.(png|jpg)$"#
        static let tempFile = #"/tmp/[\w\-]+\.(png|jpg|jpeg|gif|svg)$"#

        // Common clipboard/paste indicators
        static let pastedImage = #"\[image:[\w\-]+\]"#
        static let clipboardRef = #"<clipboard:image>"#

        // Design tool export patterns
        static let figmaExport = #"[\w\-]+@[0-9]+x\.(png|jpg|svg)$"#
        static let sketchExport = #"[\w\-]+\.sketch$"#
    }

    // MARK: - Public Methods

    /// Detect mockups from raw user input
    public func detectMockups(from input: String) -> DetectionResult {
        var textParts: [String] = []
        var mockupSources: [MockupSource] = []
        var guidelines: String?

        // Split input by lines and common delimiters
        let lines = input.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty {
                continue
            }

            // Check for guidelines markers
            if isGuidelineMarker(trimmed) {
                guidelines = extractGuidelines(from: lines, startingAt: line)
                continue
            }

            // Try to detect mockup sources
            if let mockupSource = detectMockupSource(from: trimmed) {
                mockupSources.append(mockupSource)
            } else {
                // It's regular text content
                textParts.append(trimmed)
            }
        }

        // Also check for embedded references in the text
        let embeddedMockups = extractEmbeddedMockups(from: textParts.joined(separator: PRDDataConstants.Separators.space))
        mockupSources.append(contentsOf: embeddedMockups)

        // Clean text from mockup references
        let cleanedText = cleanTextFromMockupReferences(textParts.joined(separator: PRDDataConstants.Separators.newline))

        return DetectionResult(
            textContent: cleanedText,
            mockupSources: mockupSources,
            guidelines: guidelines
        )
    }

    /// Process and normalize mockup sources to file paths
    public func normalizeMockupPaths(_ sources: [MockupSource]) async -> [String] {
        var paths: [String] = []

        for source in sources {
            switch source {
            case .filePath(let path):
                // Expand ~ and resolve relative paths
                let expandedPath = NSString(string: path).expandingTildeInPath
                if FileManager.default.fileExists(atPath: expandedPath) {
                    paths.append(expandedPath)
                }

            case .url(let urlString):
                // Download the file to a temporary location
                if let tempPath = await downloadImage(from: urlString) {
                    paths.append(tempPath)
                }

            case .base64Image(let base64):
                // Save base64 to temporary file
                if let tempPath = saveBase64Image(base64) {
                    paths.append(tempPath)
                }

            case .temporaryFile(let path):
                // Verify the temp file still exists
                if FileManager.default.fileExists(atPath: path) {
                    paths.append(path)
                }

            case .clipboardReference(let ref):
                // Try to get clipboard content (platform-specific)
                if let clipboardPath = getClipboardImagePath(ref) {
                    paths.append(clipboardPath)
                }
            }
        }

        return paths
    }

    // MARK: - Private Detection Methods

    private func detectMockupSource(from input: String) -> MockupSource? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for base64 image
        if trimmed.hasPrefix(PRDDataConstants.Prefixes.dataImage) {
            return .base64Image(trimmed)
        }

        // Check for URLs
        if trimmed.hasPrefix(PRDDataConstants.Prefixes.http) || trimmed.hasPrefix(PRDDataConstants.Prefixes.https) {
            if isImageURL(trimmed) {
                return .url(trimmed)
            }
        }

        // Check for file URLs
        if trimmed.hasPrefix(PRDDataConstants.Prefixes.file) {
            let path = trimmed.replacingOccurrences(of: PRDDataConstants.Prefixes.file, with: PRDDataConstants.Separators.empty)
            return .filePath(path)
        }

        // Check for clipboard references
        if trimmed.contains(PRDAnalysisConstants.ClipboardIndicators.clipboard) || trimmed.contains(PRDAnalysisConstants.ClipboardIndicators.imageMarker) {
            return .clipboardReference(trimmed)
        }

        // Check for file paths
        if looksLikeFilePath(trimmed) {
            // Check for temp screenshot paths
            if trimmed.contains(PRDDataConstants.Prefixes.varFolders) || trimmed.contains(PRDDataConstants.Prefixes.tmp) {
                return .temporaryFile(trimmed)
            }
            return .filePath(trimmed)
        }

        return nil
    }

    private func looksLikeFilePath(_ input: String) -> Bool {
        // Check for image file extensions
        let imageExtensions = PRDDataConstants.FileExtensions.allImageExtensions
        let lowercased = input.lowercased()

        for ext in imageExtensions {
            if lowercased.hasSuffix(".\(ext)") {
                return true
            }
        }

        // Check if it starts with path indicators
        if input.hasPrefix(PRDDataConstants.Prefixes.root) || input.hasPrefix(PRDDataConstants.Prefixes.current) || input.hasPrefix(PRDDataConstants.Prefixes.parent) || input.hasPrefix(PRDDataConstants.Prefixes.home) {
            return true
        }

        return false
    }

    private func isImageURL(_ url: String) -> Bool {
        let imageExtensions = PRDDataConstants.FileExtensions.webImageExtensions
        let lowercased = url.lowercased()

        for ext in imageExtensions {
            if lowercased.contains(".\(ext)") {
                return true
            }
        }

        // Check for image hosting services
        let imageHosts = PRDDataConstants.ImageHosts.hosts
        for host in imageHosts {
            if lowercased.contains(host) {
                return true
            }
        }

        return false
    }

    private func isGuidelineMarker(_ input: String) -> Bool {
        let markers = PRDAnalysisConstants.GuidelineMarkers.markers
        let lowercased = input.lowercased()

        for marker in markers {
            if lowercased.hasPrefix(marker) {
                return true
            }
        }

        return false
    }

    private func extractGuidelines(from lines: [String], startingAt startLine: String) -> String {
        var collectingGuidelines = false
        var guidelines: [String] = []

        for line in lines {
            if line == startLine {
                collectingGuidelines = true
                // Extract content after the marker
                if let colonIndex = line.firstIndex(of: ":") {
                    let content = String(line[line.index(after: colonIndex)...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !content.isEmpty {
                        guidelines.append(content)
                    }
                }
                continue
            }

            if collectingGuidelines {
                // Stop if we hit another section or mockup reference
                if looksLikeFilePath(line) || line.hasPrefix("#") || line.isEmpty {
                    break
                }
                guidelines.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        return guidelines.joined(separator: "\n")
    }

    private func extractEmbeddedMockups(from text: String) -> [MockupSource] {
        var mockups: [MockupSource] = []

        // Look for markdown image syntax: ![alt](path)
        let markdownImageRegex = try? NSRegularExpression(
            pattern: #"!\[([^\]]*)\]\(([^)]+)\)"#,
            options: .caseInsensitive
        )

        if let matches = markdownImageRegex?.matches(
            in: text,
            options: [],
            range: NSRange(location: 0, length: text.count)
        ) {
            for match in matches {
                if let range = Range(match.range(at: 2), in: text) {
                    let path = String(text[range])
                    if let source = detectMockupSource(from: path) {
                        mockups.append(source)
                    }
                }
            }
        }

        // Look for HTML img tags
        let htmlImageRegex = try? NSRegularExpression(
            pattern: #"<img[^>]+src=["']([^"']+)["'][^>]*>"#,
            options: .caseInsensitive
        )

        if let matches = htmlImageRegex?.matches(
            in: text,
            options: [],
            range: NSRange(location: 0, length: text.count)
        ) {
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    let path = String(text[range])
                    if let source = detectMockupSource(from: path) {
                        mockups.append(source)
                    }
                }
            }
        }

        return mockups
    }

    private func cleanTextFromMockupReferences(_ text: String) -> String {
        var cleaned = text

        // Remove markdown images
        cleaned = cleaned.replacingOccurrences(
            of: #"!\[([^\]]*)\]\([^)]+\)"#,
            with: "",
            options: .regularExpression
        )

        // Remove HTML img tags
        cleaned = cleaned.replacingOccurrences(
            of: #"<img[^>]+>"#,
            with: "",
            options: .regularExpression
        )

        // Remove standalone file paths
        let lines = cleaned.components(separatedBy: .newlines)
        let filteredLines = lines.filter { !looksLikeFilePath($0.trimmingCharacters(in: .whitespaces)) }

        return filteredLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Helper Methods

    private func downloadImage(from urlString: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = url.lastPathComponent.isEmpty ? "mockup.png" : url.lastPathComponent
            let tempPath = tempDir.appendingPathComponent(fileName)

            try data.write(to: tempPath)
            return tempPath.path
        } catch {
            DebugLogger.debug("Failed to download image: \(error)", prefix: "MockupInputDetector")
            return nil
        }
    }

    private func saveBase64Image(_ base64String: String) -> String? {
        // Extract the actual base64 data (after the comma)
        let components = base64String.components(separatedBy: PRDDataConstants.Separators.comma)
        guard components.count == 2,
              let imageData = Data(base64Encoded: components[1]) else {
            return nil
        }

        // Determine file extension from the data URL
        let mimeType = components[0].components(separatedBy: PRDDataConstants.Separators.semicolon)[0]
            .replacingOccurrences(of: PRDDataConstants.MimeTypes.dataPrefix, with: PRDDataConstants.Separators.empty)
        let ext = mimeType.replacingOccurrences(of: PRDDataConstants.MimeTypes.imagePrefix, with: PRDDataConstants.Separators.empty)
            .replacingOccurrences(of: PRDDataConstants.MimeTypes.xmlSuffix, with: PRDDataConstants.Separators.empty)

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(PRDDataConstants.Defaults.mockupPrefix)\(UUID().uuidString).\(ext)"
        let tempPath = tempDir.appendingPathComponent(fileName)

        do {
            try imageData.write(to: tempPath)
            return tempPath.path
        } catch {
            DebugLogger.debug("Failed to save base64 image: \(error)", prefix: "MockupInputDetector")
            return nil
        }
    }

    private func getClipboardImagePath(_ reference: String) -> String? {
        // Platform-specific clipboard handling would go here
        // For now, return nil as this requires platform-specific APIs
        return nil
    }
}