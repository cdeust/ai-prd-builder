import Foundation

/// Collects concrete evidence from the file system for hypothesis verification
public struct EvidenceCollector {

    private let fileManager = FileManager.default

    /// Search for files matching a pattern
    public func findFiles(
        matching pattern: String,
        in directory: String
    ) -> [String] {
        var results: [String] = []

        let url = URL(fileURLWithPath: directory)

        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                let path = fileURL.path

                // Check if file matches pattern
                if matchesPattern(path: path, pattern: pattern) {
                    results.append(path)
                }
            }
        }

        return results
    }

    /// Search for content in files
    public func searchContent(
        pattern: String,
        in files: [String]
    ) -> [(file: String, line: Int, content: String)] {
        var results: [(file: String, line: Int, content: String)] = []

        for file in files {
            if let content = try? String(contentsOfFile: file) {
                let lines = content.split(separator: "\n")

                for (index, line) in lines.enumerated() {
                    if line.contains(pattern) {
                        results.append((
                            file: file,
                            line: index + 1,
                            content: String(line).trimmingCharacters(in: .whitespaces)
                        ))
                    }
                }
            }
        }

        return results
    }

    /// Extract code snippet around a line
    public func extractSnippet(
        from file: String,
        line: Int,
        context: Int = 2
    ) -> String? {
        guard let content = try? String(contentsOfFile: file) else {
            return nil
        }

        let lines = content.split(separator: "\n").map { String($0) }

        let startLine = max(0, line - context - 1)
        let endLine = min(lines.count - 1, line + context - 1)

        var snippet = ""
        for i in startLine...endLine {
            let lineNum = i + 1
            let prefix = lineNum == line ? ">" : " "
            snippet += "\(prefix) \(lineNum): \(lines[i])\n"
        }

        return snippet
    }

    /// Check if path matches a glob pattern
    private func matchesPattern(path: String, pattern: String) -> Bool {
        // Simple pattern matching (would use fnmatch in production)
        if pattern.contains("*") {
            let components = pattern.split(separator: "*")
            if components.count == 2 {
                let prefix = String(components[0])
                let suffix = String(components[1])
                return path.contains(prefix) && path.contains(suffix)
            }
        }
        return path.contains(pattern)
    }

    /// Analyze directory structure
    public func analyzeStructure(at path: String) -> DirectoryAnalysis {
        var fileCount = 0
        var directoryCount = 0
        var fileTypes: Set<String> = []
        var totalSize: Int64 = 0

        let url = URL(fileURLWithPath: path)

        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(
                        forKeys: [.isRegularFileKey, .isDirectoryKey, .fileSizeKey]
                    )

                    if resourceValues.isRegularFile ?? false {
                        fileCount += 1
                        if let size = resourceValues.fileSize {
                            totalSize += Int64(size)
                        }
                        fileTypes.insert(fileURL.pathExtension)
                    } else if resourceValues.isDirectory ?? false {
                        directoryCount += 1
                    }
                } catch {
                    // Skip files we can't read
                }
            }
        }

        return DirectoryAnalysis(
            fileCount: fileCount,
            directoryCount: directoryCount,
            fileTypes: Array(fileTypes),
            totalSize: totalSize,
            path: path
        )
    }

    public struct DirectoryAnalysis {
        public let fileCount: Int
        public let directoryCount: Int
        public let fileTypes: [String]
        public let totalSize: Int64
        public let path: String

        public var summary: String {
            let sizeInMB = Double(totalSize) / (1024 * 1024)
            return """
            Directory: \(path)
            Files: \(fileCount)
            Directories: \(directoryCount)
            Types: \(fileTypes.joined(separator: ", "))
            Size: \(String(format: "%.2f", sizeInMB)) MB
            """
        }
    }
}

/// Evidence builder for creating detailed evidence records
public struct EvidenceBuilder {

    private let collector = EvidenceCollector()

    /// Build evidence for a hypothesis by searching the codebase
    public func buildEvidence(
        for hypothesis: String,
        searchPatterns: [String],
        basePath: String
    ) -> [Evidence] {
        var evidenceList: [Evidence] = []

        for pattern in searchPatterns {
            // Find matching files
            let files = collector.findFiles(
                matching: pattern,
                in: basePath
            )

            for file in files {
                // Extract relevant lines
                if let snippet = collector.extractSnippet(
                    from: file,
                    line: 1,
                    context: 5
                ) {
                    let evidence = Evidence(
                        type: .supporting,
                        location: "\(file):1",
                        snippet: snippet,
                        analysis: "Found matching file: \(file)"
                    )
                    evidenceList.append(evidence)
                }
            }
        }

        // If no files found, create missing evidence
        if evidenceList.isEmpty {
            evidenceList.append(Evidence(
                type: .missing,
                location: basePath,
                snippet: "No files matching patterns: \(searchPatterns.joined(separator: ", "))",
                analysis: "Expected files not found in codebase"
            ))
        }

        return evidenceList
    }

    /// Verify specific code patterns exist
    public func verifyPattern(
        pattern: String,
        in files: [String]
    ) -> VerificationResult {
        let matches = collector.searchContent(
            pattern: pattern,
            in: files
        )

        if !matches.isEmpty {
            let evidence = matches.map { match in
                Evidence(
                    type: .supporting,
                    location: "\(match.file):\(match.line)",
                    snippet: match.content,
                    analysis: "Pattern '\(pattern)' found"
                )
            }

            return VerificationResult(
                status: .confirmed,
                evidence: evidence,
                summary: "Found \(matches.count) occurrences of pattern"
            )
        } else {
            return VerificationResult(
                status: .rejected,
                evidence: [Evidence(
                    type: .missing,
                    location: "searched files",
                    snippet: nil,
                    analysis: "Pattern '\(pattern)' not found"
                )],
                summary: "Pattern not found in any files"
            )
        }
    }

    public struct VerificationResult {
        public let status: Hypothesis.VerificationStatus
        public let evidence: [Evidence]
        public let summary: String
    }
}

/// File system scanner for deep code archaeology
public struct FileSystemScanner {

    private let fileManager = FileManager.default

    /// Scan for common project patterns
    public func scanForPatterns(at path: String) -> ProjectPatterns {
        var patterns = ProjectPatterns()

        // Check for common directories
        patterns.hasModelsDirectory = directoryExists(at: "\(path)/models") ||
                                      directoryExists(at: "\(path)/src/models")

        patterns.hasServicesDirectory = directoryExists(at: "\(path)/services") ||
                                        directoryExists(at: "\(path)/src/services")

        patterns.hasControllersDirectory = directoryExists(at: "\(path)/controllers") ||
                                           directoryExists(at: "\(path)/src/controllers")

        patterns.hasTestsDirectory = directoryExists(at: "\(path)/tests") ||
                                     directoryExists(at: "\(path)/test")

        // Check for common files
        patterns.hasPackageJson = fileExists(at: "\(path)/package.json")
        patterns.hasDockerfile = fileExists(at: "\(path)/Dockerfile")
        patterns.hasReadme = fileExists(at: "\(path)/README.md")
        patterns.hasGitignore = fileExists(at: "\(path)/.gitignore")

        return patterns
    }

    private func directoryExists(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func fileExists(at path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }

    public struct ProjectPatterns {
        public var hasModelsDirectory = false
        public var hasServicesDirectory = false
        public var hasControllersDirectory = false
        public var hasTestsDirectory = false
        public var hasPackageJson = false
        public var hasDockerfile = false
        public var hasReadme = false
        public var hasGitignore = false

        public var summary: String {
            var components: [String] = []

            if hasModelsDirectory { components.append("models") }
            if hasServicesDirectory { components.append("services") }
            if hasControllersDirectory { components.append("controllers") }
            if hasTestsDirectory { components.append("tests") }

            return components.isEmpty ? "No standard directories found" :
                   "Found: \(components.joined(separator: ", "))"
        }
    }
}