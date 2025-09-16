import Foundation

/// Builds prompts for OpenAPI generation and validation
/// Centralizes all prompt construction logic
public class OpenAPIPromptBuilder {

    // MARK: - Properties

    private let prompts: PromptTemplates

    // MARK: - Initialization

    public init() {
        self.prompts = PromptTemplates()
    }

    // MARK: - Generation Prompts

    public func buildInitialGeneration(context: String) -> String {
        return String(format: prompts.initialGeneration, context)
    }

    public func buildPathSpecific(context: String, pathId: Int) -> String {
        let approach = prompts.generationApproaches[(pathId - OpenAPIPromptConstants.Indices.firstPathApproachOffset) % prompts.generationApproaches.count]

        return String(format: prompts.pathSpecific, context, approach)
    }

    public func buildAlternativeGeneration(context: String) -> String {
        return String(format: prompts.alternativeGeneration, context)
    }

    // MARK: - Correction Prompts

    public func buildCorrection(spec: String, issues: [String]) -> String {
        let categorized = categorizeIssues(issues)
        var prompt = prompts.correctionHeader

        if !categorized.critical.isEmpty {
            prompt += formatIssueSection(
                title: prompts.criticalSectionTitle,
                issues: categorized.critical
            )
        }

        if !categorized.important.isEmpty {
            prompt += formatIssueSection(
                title: prompts.importantSectionTitle,
                issues: categorized.important
            )
        }

        if !categorized.recommended.isEmpty {
            prompt += formatIssueSection(
                title: prompts.recommendedSectionTitle,
                issues: categorized.recommended
            )
        }

        prompt += String(format: prompts.correctionFooter, spec)
        return prompt
    }

    public func buildCorrectionWithMemory(
        spec: String,
        issues: [String],
        fixedIssues: [String]
    ) -> String {
        var prompt = ""

        if !fixedIssues.isEmpty {
            prompt = prompts.fixedIssuesHeader
            prompt += fixedIssues.map { OpenAPIPromptConstants.Messages.bulletPrefix + $0 }.joined(separator: "\n")
            prompt += prompts.sectionSeparator
        }

        prompt += buildCorrection(spec: spec, issues: issues)
        return prompt
    }

    public func buildPersistentIssue(
        spec: String,
        persistentIssues: [String],
        fixedIssues: [String]
    ) -> String {
        var prompt = prompts.persistentIssuesHeader
        prompt += persistentIssues.enumerated().map {
            "\($0.offset + OpenAPIPromptConstants.Indices.issueNumberOffset). \($0.element)"
        }.joined(separator: "\n")
        prompt += "\n\n"

        if !fixedIssues.isEmpty {
            prompt += prompts.keepFixesHeader
            prompt += fixedIssues.map { OpenAPIPromptConstants.Messages.bulletPrefix + $0 }.joined(separator: "\n")
            prompt += "\n"
        }

        prompt += String(format: prompts.persistentIssuesFooter, spec)
        return prompt
    }

    public func buildForceCorrection(spec: String, issues: [String]) -> String {
        return String(format: prompts.forceCorrection,
                     issues.joined(separator: "\n"),
                     spec)
    }

    // MARK: - Validation Prompts

    public func buildValidation(spec: String, knownIssues: [String] = []) -> String {
        var prompt = String(format: prompts.validationTemplate, spec)

        if !knownIssues.isEmpty {
            prompt += prompts.knownIssuesHeader
            prompt += knownIssues.map { OpenAPIPromptConstants.Messages.bulletPrefix + $0 }.joined(separator: "\n")
            prompt += prompts.additionalIssuesHint
        }

        prompt += prompts.validationFooter
        return prompt
    }

    public func buildFixApplication(issue: String, solution: String, spec: String) -> String {
        return String(format: prompts.fixApplication, issue, solution, spec)
    }

    // MARK: - Helper Methods

    private func categorizeIssues(_ issues: [String]) -> CategorizedIssues {
        var categorized = CategorizedIssues()

        for issue in issues {
            if issue.starts(with: IssueMarkers.critical) {
                categorized.critical.append(issue)
            } else if issue.starts(with: IssueMarkers.warning) {
                categorized.important.append(issue)
            } else {
                categorized.recommended.append(issue)
            }
        }

        return categorized
    }

    private func formatIssueSection(title: String, issues: [String]) -> String {
        return title + "\n" + issues.joined(separator: "\n") + prompts.sectionSeparator
    }

    // MARK: - Types

    private struct CategorizedIssues {
        var critical: [String] = []
        var important: [String] = []
        var recommended: [String] = []
    }
}

// MARK: - Prompt Templates

private struct PromptTemplates {

    // Generation prompts
    let initialGeneration = """
        Generate an OpenAPI 3.1.0 specification for: %@

        Requirements:
        • Complete and valid structure
        • All operations have operationId
        • Include examples for all schemas
        • Add security definitions if needed

        Let's think step by step to design a clean API.
        """

    let pathSpecific = """
        Generate an OpenAPI 3.1.0 specification for: %@

        Approach: %@

        Requirements:
        • Include operationId for every operation
        • Add examples for all parameters and responses
        • Define security schemes if authentication is needed
        • Use clear descriptions for LLM understanding
        • Follow OpenAPI 3.1.0 and JSON Schema 2020-12 standards

        Let's think step by step to create a comprehensive API specification.
        """

    let alternativeGeneration = """
        Generate a valid OpenAPI 3.1.0 specification for: %@

        Key requirements:
        • GET operations cannot have requestBody
        • All paths must be unique (group methods under single path)
        • Use proper response structure with content/application/json
        • Include standard HTTP status codes (200, 400, 401, 404, 500)
        • Place securitySchemes under components section

        Let's think step by step to create a well-structured API specification.
        """

    // Correction prompts
    let correctionHeader = "Fix this OpenAPI specification following these priorities:\n\n"

    let correctionFooter = """
        Current specification:
        %@

        Return a corrected OpenAPI 3.1.0 specification that:
        1. Fixes all critical issues
        2. Addresses important issues where possible
        3. Maintains LLM-friendly descriptions and examples
        4. Follows OpenAPI 3.1.0 and JSON Schema 2020-12 standards
        """

    let forceCorrection = """
        Critical issues that MUST be fixed:
        %@

        Current specification:
        %@

        Return a fully corrected OpenAPI 3.1.0 specification with ALL issues resolved.
        Focus on producing a valid, working specification that LLMs can use effectively.
        """

    // Persistent issues
    let persistentIssuesHeader = "These issues have persisted across multiple attempts:\n"

    let persistentIssuesFooter = """
        Current spec:
        %@

        IMPORTANT: Focus ONLY on fixing the persistent issues listed above.
        Do not break what's already working.

        For authentication issues: Ensure components.securitySchemes is properly defined.
        For missing examples: Add example values to parameters and schemas.
        For missing operationIds: Add unique operationId to each operation.

        Return the corrected specification.
        """

    // Validation prompts
    let validationTemplate = """
        Validate this OpenAPI specification for LLM compatibility and correctness.

        Focus on these critical aspects:
        1. Semantic clarity - Can an LLM understand what each endpoint does?
        2. Parameter completeness - Are all parameters documented with types and descriptions?
        3. Response schemas - Are all possible responses defined with clear schemas?
        4. Error handling - Are error responses documented to help LLMs recover?
        5. Authentication - Is security properly defined and implementable?

        Specification to validate:
        %@
        """

    let validationFooter = """

        Provide:
        - Valid: YES or NO
        - Confidence: 0.0 to 1.0
        - Issues: List any problems that would prevent LLMs from using this API effectively

        Focus on issues that would cause API calls to fail or return unexpected results.
        """

    // Fix application
    let fixApplication = """
        Fix this OpenAPI specification:

        Issue: %@
        Target: %@

        Current spec:
        %@

        Apply the fix while preserving all working parts.
        """

    // Section headers
    let fixedIssuesHeader = "✅ Successfully fixed these issues (keep these fixes):\n"
    let keepFixesHeader = "\n✅ Keep these successful fixes:\n"
    let knownIssuesHeader = "\n\nStructural issues already detected:\n"
    let additionalIssuesHint = "\n\nCheck for additional semantic and completeness issues beyond these.\n"

    // Issue categories
    let criticalSectionTitle = "🔴 CRITICAL (must fix):"
    let importantSectionTitle = "🟡 IMPORTANT (should fix):"
    let recommendedSectionTitle = "🟢 RECOMMENDED (nice to have):"

    // Formatting
    let bulletPrefix = OpenAPIPromptConstants.Messages.bulletPrefix
    let sectionSeparator = "\n\n"

    // Generation approaches
    let generationApproaches = [
        "Focus on completeness and clarity for LLM consumption",
        "Emphasize security, error handling, and examples",
        "Prioritize simplicity and standard patterns"
    ]
}

// MARK: - Issue Markers

private enum IssueMarkers {
    static let critical = "❌"
    static let warning = "⚠️"
    static let recommendation = "💡"
}