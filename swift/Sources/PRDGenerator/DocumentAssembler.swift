import Foundation
import CommonModels

/// Assembles PRD sections into a complete document
public final class DocumentAssembler {
    private let reportFormatter: ReportFormatter

    public init() {
        self.reportFormatter = ReportFormatter()
    }

    /// Assemble sections into a PRDocument
    public func assembleDocument(
        title: String,
        sections: [PRDSection]
    ) -> PRDocument {
        return PRDocument(
            title: title,
            sections: sections,
            metadata: buildMetadata()
        )
    }

    /// Build document metadata
    private func buildMetadata() -> [String: Any] {
        return [
            PRDDataConstants.MetadataKeys.generator: PRDDataConstants.Defaults.prdGeneratorName,
            PRDDataConstants.MetadataKeys.version: PRDDataConstants.Defaults.prdVersion,
            PRDDataConstants.MetadataKeys.timestamp: Date().timeIntervalSince1970,
            PRDDataConstants.MetadataKeys.passes: PRDDataConstants.Defaults.totalPasses,
            PRDDataConstants.MetadataKeys.approach: PRDDataConstants.Defaults.generationApproach
        ]
    }

    /// Calculate and display overall confidence
    public func displayCompletionSummary(sections: [PRDSection]) {
        print(PRDDisplayConstants.ProgressMessages.prdComplete)
        let overallConfidence = reportFormatter.calculateOverallConfidence(sections)
        print(String(format: PRDDisplayConstants.ProgressMessages.overallConfidenceFormat, overallConfidence))
    }

    /// Export document if requested
    public func exportIfRequested(
        document: PRDocument,
        exportPath: String? = nil,
        format: PRDExporter.ExportFormat = .markdown
    ) throws -> String? {
        if exportPath != nil || ProcessInfo.processInfo.environment["AUTO_EXPORT"] != nil {
            let exporter = PRDExporter()
            let path = try exporter.export(document: document, format: format, to: exportPath)
            print(String(format: PRDDisplayConstants.ProgressMessages.exportSuccessFormat, path))
            return path
        }
        return nil
    }
}