import Foundation
import CommonModels

/// Assembles PRD sections into a complete document
public final class DocumentAssembler {
    private let reportFormatter: ReportFormatter
    private let interactionHandler: UserInteractionHandler

    public init(interactionHandler: UserInteractionHandler = ConsoleInteractionHandler()) {
        self.reportFormatter = ReportFormatter()
        self.interactionHandler = interactionHandler
    }

    /// Assemble sections into a PRDocument
    public func assembleDocument(
        title: String,
        sections: [PRDSection],
        professionalAnalysis: CommonModels.ProfessionalAnalysisResult? = nil
    ) -> PRDocument {
        var finalSections = sections

        // Add professional analysis as first section if any issues detected
        if let analysis = professionalAnalysis,
           (analysis.conflictCount > 0 || analysis.challengeCount > 0 || analysis.hasCriticalIssues) {
            let analysisSection = PRDSection(
                title: "🔍 Professional Architecture Analysis",
                content: analysis.executiveSummary
            )
            // Insert after requirements analysis if it exists, otherwise at the beginning
            let insertIndex = finalSections.firstIndex(where: { $0.title.contains("Requirements Analysis") }) ?? -1
            finalSections.insert(analysisSection, at: insertIndex + 1)
        }

        return PRDocument(
            title: title,
            sections: finalSections,
            metadata: buildMetadata(),
            professionalAnalysis: professionalAnalysis
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
        interactionHandler.showInfo(PRDDisplayConstants.ProgressMessages.prdComplete)
        let overallConfidence = reportFormatter.calculateOverallConfidence(sections)
        interactionHandler.showInfo(String(format: PRDDisplayConstants.ProgressMessages.overallConfidenceFormat, overallConfidence))
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
            interactionHandler.showInfo(String(format: PRDDisplayConstants.ProgressMessages.exportSuccessFormat, path))
            return path
        }
        return nil
    }
}