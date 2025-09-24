import Foundation
import CommonModels

/// Handles exporting PRD documents to various formats
public final class PRDExporter {

    public enum ExportFormat {
        case markdown
        case json
        case html
        case text
    }

    public enum ExportError: Error, LocalizedError {
        case invalidPath(String)
        case writeFailed(String)
        case encodingFailed(String)

        public var errorDescription: String? {
            switch self {
            case .invalidPath(let path):
                return "Invalid export path: \(path)"
            case .writeFailed(let reason):
                return "Failed to write file: \(reason)"
            case .encodingFailed(let reason):
                return "Failed to encode data: \(reason)"
            }
        }
    }

    public init() {}

    /// Export PRD to specified format and location
    public func export(
        document: PRDocument,
        format: ExportFormat,
        to path: String? = nil
    ) throws -> String {
        let fileName = generateFileName(title: document.title, format: format)
        let filePath = path ?? FileManager.default.currentDirectoryPath + "/" + fileName

        let content: String
        switch format {
        case .markdown:
            content = exportToMarkdown(document)
        case .json:
            content = try exportToJSON(document)
        case .html:
            content = exportToHTML(document)
        case .text:
            content = exportToPlainText(document)
        }

        // Write to file
        do {
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
            return filePath
        } catch {
            throw ExportError.writeFailed(error.localizedDescription)
        }
    }

    /// Export to string without writing to file
    public func exportToString(document: PRDocument, format: ExportFormat) throws -> String {
        switch format {
        case .markdown:
            return exportToMarkdown(document)
        case .json:
            return try exportToJSON(document)
        case .html:
            return exportToHTML(document)
        case .text:
            return exportToPlainText(document)
        }
    }

    // MARK: - Private Export Methods

    private func exportToMarkdown(_ document: PRDocument) -> String {
        var markdown = "# \(document.title)\n\n"

        // Add metadata as comments
        if let timestamp = document.metadata["timestamp"] as? TimeInterval {
            let date = Date(timeIntervalSince1970: timestamp)
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .medium
            markdown += "<!-- Generated: \(formatter.string(from: date)) -->\n"
        }

        if let generator = document.metadata["generator"] as? String {
            markdown += "<!-- Generator: \(generator) -->\n"
        }

        markdown += "\n"

        // Add sections
        for section in document.sections {
            markdown += "## \(section.title)\n\n"
            markdown += section.content + "\n\n"
        }

        return markdown
    }

    private func exportToJSON(_ document: PRDocument) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        // Create JSON structure
        let jsonStructure: [String: Any] = [
            "title": document.title,
            "sections": document.sections.map { section in
                [
                    "title": section.title,
                    "content": section.content
                ]
            },
            "metadata": document.metadata
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: jsonStructure, options: [.prettyPrinted, .sortedKeys])
            guard let jsonString = String(data: data, encoding: .utf8) else {
                throw ExportError.encodingFailed("Failed to convert JSON data to string")
            }
            return jsonString
        } catch {
            throw ExportError.encodingFailed(error.localizedDescription)
        }
    }

    private func exportToHTML(_ document: PRDocument) -> String {
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(document.title)</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
                    line-height: 1.6;
                    max-width: 900px;
                    margin: 0 auto;
                    padding: 20px;
                    background-color: #f5f5f7;
                }
                h1 {
                    color: #1d1d1f;
                    border-bottom: 2px solid #0071e3;
                    padding-bottom: 10px;
                }
                h2 {
                    color: #333;
                    margin-top: 30px;
                }
                pre {
                    background-color: #f0f0f0;
                    padding: 10px;
                    border-radius: 5px;
                    overflow-x: auto;
                }
                code {
                    background-color: #f0f0f0;
                    padding: 2px 5px;
                    border-radius: 3px;
                }
                .metadata {
                    color: #666;
                    font-size: 0.9em;
                    margin-bottom: 20px;
                }
            </style>
        </head>
        <body>
            <h1>\(escapeHTML(document.title))</h1>
        """

        // Add metadata
        if let timestamp = document.metadata["timestamp"] as? TimeInterval {
            let date = Date(timeIntervalSince1970: timestamp)
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .medium
            html += "<div class=\"metadata\">Generated: \(formatter.string(from: date))</div>\n"
        }

        // Add sections
        for section in document.sections {
            html += "<h2>\(escapeHTML(section.title))</h2>\n"
            html += "<div>\(convertMarkdownToHTML(section.content))</div>\n"
        }

        html += """
        </body>
        </html>
        """

        return html
    }

    private func exportToPlainText(_ document: PRDocument) -> String {
        var text = "\(document.title)\n"
        text += String(repeating: "=", count: document.title.count) + "\n\n"

        // Add metadata
        if let timestamp = document.metadata["timestamp"] as? TimeInterval {
            let date = Date(timeIntervalSince1970: timestamp)
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .medium
            text += "Generated: \(formatter.string(from: date))\n\n"
        }

        // Add sections
        for section in document.sections {
            text += "\(section.title)\n"
            text += String(repeating: "-", count: section.title.count) + "\n\n"
            text += section.content + "\n\n"
        }

        return text
    }

    // MARK: - Helper Methods

    private func generateFileName(title: String, format: ExportFormat) -> String {
        let cleanTitle = title
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .lowercased()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let fileExtension: String
        switch format {
        case .markdown: fileExtension = "md"
        case .json: fileExtension = "json"
        case .html: fileExtension = "html"
        case .text: fileExtension = "txt"
        }

        return "prd_\(cleanTitle)_\(timestamp).\(fileExtension)"
    }

    private func escapeHTML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private func convertMarkdownToHTML(_ markdown: String) -> String {
        // Basic markdown to HTML conversion
        var html = escapeHTML(markdown)

        // Convert code blocks
        html = html.replacingOccurrences(of: "```([\\s\\S]*?)```",
                                        with: "<pre><code>$1</code></pre>",
                                        options: .regularExpression)

        // Convert inline code
        html = html.replacingOccurrences(of: "`([^`]+)`",
                                        with: "<code>$1</code>",
                                        options: .regularExpression)

        // Convert bold
        html = html.replacingOccurrences(of: "\\*\\*([^\\*]+)\\*\\*",
                                        with: "<strong>$1</strong>",
                                        options: .regularExpression)

        // Convert italic
        html = html.replacingOccurrences(of: "\\*([^\\*]+)\\*",
                                        with: "<em>$1</em>",
                                        options: .regularExpression)

        // Convert line breaks
        html = html.replacingOccurrences(of: "\n", with: "<br>\n")

        return html
    }
}