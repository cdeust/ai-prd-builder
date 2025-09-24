import Foundation
import CommonModels
import ThinkingCore

/// Handles formatting of various reports and content
public final class ReportFormatter {

    public init() {}

    /// Formats the requirements analysis for display
    public func formatRequirementsAnalysis(_ requirements: EnrichedRequirements) -> String {
        var content = "## Initial Analysis\n"
        content += "- **Initial Confidence**: \(requirements.initialConfidence)%\n"

        if !requirements.clarifications.isEmpty {
            content += "\n## Clarifications Provided\n"
            for (question, answer) in requirements.clarifications {
                content += "\n**Q:** \(question)\n"
                content += "**A:** \(answer)\n"
            }
        }

        if !requirements.assumptions.isEmpty {
            content += "\n## Validated Assumptions\n"
            for assumption in requirements.assumptions {
                content += "- \(assumption)\n"
            }
        }

        if !requirements.gaps.isEmpty {
            content += "\n## Identified Gaps (to be addressed)\n"
            for gap in requirements.gaps {
                content += "- \(gap)\n"
            }
        }

        return content
    }

    /// Formats the technical stack context for display
    public func formatStackContext(_ stack: StackContext) -> String {
        return """
        ## Technical Stack
        - **Language**: \(stack.language)
        - **Test Framework**: \(stack.testFramework ?? PRDConstants.Defaults.tbd)
        - **CI/CD Pipeline**: \(stack.cicdPipeline ?? PRDConstants.Defaults.tbd)
        - **Deployment**: \(stack.deployment ?? PRDConstants.Defaults.tbd)
        - **Database**: \(stack.database ?? PRDConstants.Defaults.tbd)
        - **Security**: \(stack.security ?? PRDConstants.Defaults.tbd)
        - **Performance**: \(stack.performance ?? PRDConstants.Defaults.tbd)
        - **Integrations**: \(stack.integrations.joined(separator: ", "))

        ## Discovery Questions
        \(stack.questions)
        """
    }

    /// Formats the validation report
    public func formatValidationReport(_ report: ValidationReport) -> String {
        // Only show validated assumptions that are valid
        let validatedAssumptions = report.results.filter { $0.isValid }

        if validatedAssumptions.isEmpty {
            return "No assumptions requiring validation were identified during PRD generation."
        }

        var result = "The following assumptions have been validated for this PRD:\n\n"

        for (index, validation) in validatedAssumptions.enumerated() {
            result += "**\(index + 1). \(validation.assumptionStatement)**\n"
            result += "   *Validation*: \(validation.implications)\n"
            if !validation.evidence.isEmpty {
                result += "   *Supporting Evidence*: \(validation.evidence.joined(separator: "; "))\n"
            }
            result += "   *Confidence Level*: \(Int(validation.confidence * 100))%\n\n"
        }

        return result
    }

    /// Formats content with confidence
    public func formatWithConfidence(_ content: String, confidence: Int) -> String {
        return content + String(format: PRDConstants.ContentFormatting.confidenceFormat, confidence)
    }

    /// Formats content with confidence and clarifications needed
    public func formatWithClarifications(_ content: String, confidence: Int, clarifications: [String]) -> String {
        var result = content + String(format: PRDConstants.ContentFormatting.confidenceFormat, confidence)

        if !clarifications.isEmpty {
            result += "\n\n**Clarifications Needed:**"
            for clarification in clarifications {
                result += "\n- \(clarification)"
            }
        }

        return result
    }

    /// Formats content with confidence and stack awareness
    public func formatWithStackAwareness(_ content: String, confidence: Int) -> String {
        return content +
               String(format: PRDConstants.ContentFormatting.confidenceFormat, confidence) +
               PRDConstants.ContentFormatting.stackAwareFormat
    }

    /// Formats content with confidence and test framework
    public func formatWithTestFramework(_ content: String, confidence: Int, testFramework: String?) -> String {
        let framework = testFramework ?? PRDConstants.Defaults.xctest
        return content +
               String(format: PRDConstants.ContentFormatting.confidenceFormat, confidence) +
               String(format: PRDConstants.ContentFormatting.testFrameworkFormat, framework)
    }

    /// Formats content with confidence and pipeline
    public func formatWithPipeline(_ content: String, confidence: Int, pipeline: String?) -> String {
        let pipelineName = pipeline ?? PRDConstants.Defaults.unknown
        return content +
               String(format: PRDConstants.ContentFormatting.confidenceFormat, confidence) +
               String(format: PRDConstants.ContentFormatting.pipelineFormat, pipelineName)
    }

    /// Formats a PRD title from input
    public func formatTitle(_ input: String) -> String {
        // Extract first line or first 50 characters as title
        let firstLine = input.split(separator: "\n").first ?? ""
        let title = String(firstLine.prefix(50))
        return title + PRDConstants.ContentFormatting.prdSuffix
    }

    /// Calculates overall confidence from sections
    public func calculateOverallConfidence(_ sections: [PRDSection]) -> Int {
        // Extract confidence from content since PRDSection doesn't have metadata
        let confidences = sections.compactMap { section -> Int? in
            // Look for confidence in the content
            if let range = section.content.range(of: PRDConstants.ContentFormatting.confidencePrefix),
               let endRange = section.content[range.upperBound...].range(of: PRDConstants.ContentFormatting.percentSuffix) {
                let confidenceStr = String(section.content[range.upperBound..<endRange.lowerBound])
                return Int(confidenceStr)
            }
            return nil
        }
        guard !confidences.isEmpty else { return 0 }
        return confidences.reduce(0, +) / confidences.count
    }

    /// Enhances prompt with stack context
    public func enhancePromptWithStack(_ prompt: String, stack: StackContext) -> String {
        let contextTag = String(
            format: PRDConstants.StackFormatting.stackContextTag,
            stack.language,
            stack.database ?? PRDConstants.Defaults.tbd,
            stack.security ?? PRDConstants.Defaults.tbd
        )
        return prompt + contextTag
    }

    /// Enhances test prompt with stack context
    public func enhanceTestPromptWithStack(_ prompt: String, stack: StackContext) -> String {
        let testFramework = stack.testFramework ?? PRDConstants.Defaults.xctest
        let replacedPrompt = prompt.replacingOccurrences(
            of: PRDConstants.StackFormatting.useXCTestFormat,
            with: String(format: PRDConstants.StackFormatting.useFrameworkFormat, testFramework)
        )
        let contextTag = String(format: PRDConstants.StackFormatting.testContextTag, testFramework)
        return replacedPrompt + contextTag
    }

    /// Enhances roadmap prompt with CI/CD context
    public func enhanceRoadmapPromptWithStack(_ prompt: String, stack: StackContext) -> String {
        let contextTag = String(
            format: PRDConstants.StackFormatting.cicdContextTag,
            stack.cicdPipeline ?? PRDConstants.Defaults.unknown,
            stack.deployment ?? PRDConstants.Defaults.unknown
        )
        return prompt + contextTag
    }
}