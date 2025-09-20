import Foundation
import CommonModels
import DomainCore

/// Orchestrates AI-based analysis of requirements and technical stack
public final class AnalysisOrchestrator {
    private let provider: AIProvider

    public init(provider: AIProvider) {
        self.provider = provider
    }

    /// Performs initial requirements analysis
    public func analyzeRequirements(input: String) async throws -> RequirementsAnalysis {
        let analysisPrompt = """
        <task>Analyze Requirements Completeness</task>

        <input>\(input)</input>

        <instruction>
        Analyze the provided product requirements and identify:
        1. Areas that need clarification for accurate PRD generation
        2. Implicit assumptions that should be validated
        3. Critical gaps that would affect implementation
        4. Overall confidence score (0-100) for generating a complete PRD

        Focus on ACTIONABLE clarifications that would significantly improve the PRD quality.

        Format your response as JSON:
        ```json
        {
          "confidence": 75,
          "clarifications_needed": [
            "What specific authentication method should be used (OAuth, JWT, etc.)?",
            "Should the snippets support versioning or history tracking?",
            "What are the expected performance requirements (response times, concurrent users)?"
          ],
          "assumptions": [
            "Assuming REST API architecture",
            "Assuming PostgreSQL for database"
          ],
          "gaps": [
            "No error handling strategy defined",
            "Missing scalability requirements"
          ]
        }
        ```
        </instruction>
        """

        return try await performAnalysis(prompt: analysisPrompt)
    }

    /// Analyzes technical stack requirements
    public func analyzeTechnicalStack(input: String) async throws -> RequirementsAnalysis {
        let stackPrompt = """
        <task>Analyze Technical Stack Requirements</task>

        <input>\(input)</input>

        <instruction>
        Analyze the technical requirements and identify:
        1. Missing technical stack details that need clarification
        2. Platform-specific requirements that should be validated
        3. Integration requirements that need confirmation
        4. Performance and scalability requirements

        Focus on TECHNICAL clarifications that affect architecture and implementation.

        Format your response as JSON:
        ```json
        {
          "confidence": 70,
          "clarifications_needed": [
            "What programming language/framework should be used?",
            "What database system is preferred (PostgreSQL, MongoDB, etc.)?",
            "What are the expected performance requirements (response times, concurrent users)?",
            "Should this include CI/CD pipeline setup?",
            "What authentication method should be implemented (JWT, OAuth, etc.)?"
          ],
          "assumptions": [
            "Assuming REST API architecture",
            "Assuming cloud deployment"
          ],
          "gaps": [
            "No deployment strategy specified",
            "Missing security requirements"
          ]
        }
        ```
        </instruction>
        """

        return try await performAnalysis(prompt: stackPrompt)
    }

    /// Re-analyzes requirements with enriched context
    public func reanalyzeWithContext(enrichedInput: String) async throws -> RequirementsAnalysis {
        let reanalysisPrompt = """
        <task>Re-analyze Requirements with Additional Context</task>

        <input>\(enrichedInput)</input>

        <instruction>
        Re-analyze the requirements with the additional clarifications provided.
        Calculate a new confidence score based on the enriched context.

        Format your response as JSON:
        ```json
        {
          "confidence": 85,
          "clarifications_needed": [],
          "assumptions": [
            "Using provided technology choices",
            "Following specified requirements"
          ],
          "gaps": []
        }
        ```
        </instruction>
        """

        return try await performAnalysis(prompt: reanalysisPrompt)
    }

    // MARK: - Private Methods

    private func performAnalysis(prompt: String) async throws -> RequirementsAnalysis {
        let messages = [
            ChatMessage(role: .system, content: PRDPrompts.systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return parseAnalysisResponse(response)
        case .failure(let error):
            throw error
        }
    }

    private func parseAnalysisResponse(_ response: String) -> RequirementsAnalysis {
        // Extract JSON from response
        guard let jsonStart = response.range(of: "```json\n"),
              let jsonEnd = response.range(of: "\n```", range: jsonStart.upperBound..<response.endIndex) else {
            // Fallback if no JSON found
            return RequirementsAnalysis(
                confidence: 50,
                clarificationsNeeded: [],
                assumptions: [],
                gaps: []
            )
        }

        let jsonContent = String(response[jsonStart.upperBound..<jsonEnd.lowerBound])

        guard let data = jsonContent.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return RequirementsAnalysis(
                confidence: 50,
                clarificationsNeeded: [],
                assumptions: [],
                gaps: []
            )
        }

        return RequirementsAnalysis(
            confidence: json["confidence"] as? Int ?? 50,
            clarificationsNeeded: json["clarifications_needed"] as? [String] ?? [],
            assumptions: json["assumptions"] as? [String] ?? [],
            gaps: json["gaps"] as? [String] ?? []
        )
    }
}