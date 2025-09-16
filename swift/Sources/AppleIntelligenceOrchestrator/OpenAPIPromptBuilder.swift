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
        Generate a complete OpenAPI 3.1.0 specification for: %@

        CRITICAL REQUIREMENTS:
        1. Output a SINGLE valid YAML document
        2. Start with 'openapi: 3.1.0' (no text before)
        3. End after the last YAML line (no text after)
        4. DO NOT use markdown code fences (```yaml)
        5. All paths must have proper response schemas with content/application/json/schema structure
        6. Define all schemas in components/schemas section
        7. NO references to components/responses or components/requestBodies (use inline content)
        8. Include operationId for every operation
        9. Use this exact structure:

        openapi: 3.1.0
        info:
          title: [Service Name]
          version: 1.0.0
          description: [Description]
        servers:
          - url: https://api.example.com/v1
            description: Production
        paths:
          [Define all paths here with inline response content]
        components:
          schemas:
            [Define all schemas here]
          securitySchemes:
            BearerAuth:
              type: http
              scheme: bearer
        security:
          - BearerAuth: []
        """

    let pathSpecific = """
        Generate a complete OpenAPI 3.1.0 specification for: %@

        Approach: %@

        STRICT RULES:
        1. Output ONLY valid YAML (no markdown, no explanations)
        2. All responses use content/application/json/schema structure
        3. Define schemas in components/schemas, NOT components/responses
        4. Every operation needs operationId
        5. Include realistic examples in schemas
        6. For error responses, reference #/components/schemas/Error

        Example response structure:
        responses:
          '200':
            description: Success
            content:
              application/json:
                schema:
                  $ref: '#/components/schemas/ResourceName'
          '400':
            description: Bad Request
            content:
              application/json:
                schema:
                  $ref: '#/components/schemas/Error'
        """

    let alternativeGeneration = """
        Generate a valid OpenAPI 3.1.0 specification for: %@

        VALIDATION RULES:
        • GET/DELETE operations: NO requestBody
        • All paths must be unique (group methods under same path)
        • Response structure: responses → status → content → application/json → schema
        • Standard status codes: 200, 201, 204, 400, 401, 404, 500
        • Components structure:
          - schemas: All data models
          - securitySchemes: Authentication methods
          - NO components/responses or components/requestBodies sections

        OUTPUT FORMAT:
        Pure YAML starting with 'openapi: 3.1.0'
        No markdown fences, no explanatory text
        """

    // Correction prompts
    let correctionHeader = "Fix this OpenAPI specification following these priorities:\n\n"

    let correctionFooter = """
        Current specification:
        %@

        Return ONLY the corrected OpenAPI 3.1.0 specification:
        1. Fix all critical structural issues first
        2. Ensure all $refs point to existing definitions
        3. Use content/application/json/schema for all responses
        4. Remove any components/responses or components/requestBodies sections
        5. Output pure YAML with no markdown or explanations
        """

    let forceCorrection = """
        CRITICAL ISSUES TO FIX:
        %@

        Current specification:
        %@

        INSTRUCTIONS:
        1. Output ONLY valid YAML (no markdown fences)
        2. Fix ALL structural issues
        3. Ensure single document structure
        4. All responses must use content/application/json/schema
        5. Define all referenced schemas in components/schemas
        6. Remove components/responses and components/requestBodies if present
        7. Start output with 'openapi: 3.1.0'
        """

    // Persistent issues
    let persistentIssuesHeader = "These issues have persisted across multiple attempts:\n"

    let persistentIssuesFooter = """
        Current spec:
        %@

        FIX THESE SPECIFIC ISSUES:
        - Mixed documents: Ensure single YAML document
        - Dangling refs: Define all referenced schemas
        - Response structure: Use content/application/json/schema
        - Components structure: Only schemas and securitySchemes

        OUTPUT REQUIREMENTS:
        - Pure YAML, no markdown
        - Start with 'openapi: 3.1.0'
        - Single cohesive document
        """

    // Validation prompts
    let validationTemplate = """
        Validate this OpenAPI specification for correctness.

        CRITICAL CHECKS:
        1. Document structure - Is it a single valid YAML document?
        2. Reference integrity - Do all $refs point to existing definitions?
        3. Response structure - Do all responses use content/application/json/schema?
        4. Components structure - Are there only schemas and securitySchemes?
        5. No dangling refs - No references to components/responses or components/requestBodies?

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