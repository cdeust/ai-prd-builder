import Foundation

/// Simple conversational PRD builder
/// Manages the conversation loop to build structured requirements
/// Integrates domain knowledge, glossary, and metrics for better specs
public struct ConversationalPRD {
    
    /// Safely escape a string for JSON inclusion
    private static func escapeForJSON(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: "'", with: "\\'")
    }
    
    /// Clean JSON response by removing markdown code blocks and extracting JSON
    private static func cleanJSONResponse(_ response: String) -> String {
        var cleaned = response
        
        // Remove markdown code blocks
        if cleaned.contains("```") {
            // Remove ```json at the start
            cleaned = cleaned.replacingOccurrences(of: "```json\n", with: "")
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
            // Remove ``` at the end
            cleaned = cleaned.replacingOccurrences(of: "\n```", with: "")
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        
        // Find the first { or [ and extract from there
        if let firstBrace = cleaned.firstIndex(of: "{") {
            cleaned = String(cleaned[firstBrace...])
        } else if let firstBracket = cleaned.firstIndex(of: "[") {
            cleaned = String(cleaned[firstBracket...])
        }
        
        // Find the last } or ] and extract up to there
        if let lastBrace = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[...lastBrace])
        } else if let lastBracket = cleaned.lastIndex(of: "]") {
            cleaned = String(cleaned[...lastBracket])
        }
        
        // Trim whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    /// Start a PRD conversation with domain awareness
    public static func startConversation(
        initialRequest: String,
        orchestrator: Orchestrator
    ) async throws -> String {
        
        // Use Context Engineering - let AI understand naturally
        // No domain detection needed - AI understands context through proper prompting
        
        // Get relevant acronyms from glossary
        let glossary = orchestrator.glossaryForCurrentSession()
        let glossaryContext = await buildGlossaryContext(glossary)
        
        // First, understand what the user wants using Context Engineering
        
        let analysisPrompt = """
        User wants to build: \(initialRequest)

        \(glossaryContext)
        
        Analyze this request and respond with:
        1. Your understanding of what needs to be built
        2. Critical questions to create a complete specification
        3. What information is already clear vs what's missing
        
        IMPORTANT: Ensure all JSON strings are properly escaped. Never use single quotes in JSON.
        Replace any apostrophes with escaped quotes or rephrase to avoid them.
        
        Output as JSON:
        {
          "understanding": "what you understand",
          "clear_requirements": ["what is already specified"],
          "questions": [
            "specific question 1", 
            "specific question 2"
          ],
          "resource_questions": [
            "Do you have any design mockups (Figma/Sketch) I should reference? If yes, please share the links.",
            "Is there existing documentation (Confluence/Wiki) I should know about? If yes, please share the links."
          ],
          "next_step": "what to ask first",
          "resources_check": {
            "needs_ui": true,
            "needs_docs": true
          }
        }
        """
        
        do {
            let (analysis, _) = try await orchestrator.sendMessage(
                analysisPrompt,
                systemPrompt: "You are a technical product manager helping to create detailed specifications.",
                needsJSON: true
            )
            
            // Clean the response - remove markdown code blocks if present
            let cleanedAnalysis = cleanJSONResponse(analysis)
            
            
            return cleanedAnalysis
        } catch {
            throw error
        }
    }
    
    /// Continue building the PRD with new information
    public static func continueConversation(
        originalRequest: String,
        previousContext: String,
        userResponse: String,
        orchestrator: Orchestrator,
        attemptNumber: Int = 1
    ) async throws -> String {
        
        // After 5 attempts, let AI analyze what's missing
        let fallbackGuidance = attemptNumber >= 5 ? """

        IMPORTANT: This is attempt #\(attemptNumber).
        Analyze the conversation so far and identify the most critical missing information.
        Focus on understanding what's truly needed to complete the PRD based on the specific context.
        """ : ""
        
        let prompt = """
        Building PRD for: \(originalRequest)

        Previous context: \(previousContext)
        User provided: \(userResponse)

        CONTEXT ENGINEERING ANALYSIS:
        Apply these principles to understand the request:

        1. FOUNDATIONAL CONTEXT (Domain Understanding)
           - Infer the actual domain from the conversation content, not keywords
           - Identify business entities and their relationships
           - Extract constraints (technical, regulatory, business)
           - Recognize industry-specific terminology naturally used

        2. INTEGRATION CONTEXT (System Connections)
           - Identify mentioned external systems/APIs
           - Map data flows and dependencies
           - Understand stakeholder touchpoints
           - Capture process integrations

        3. INTERACTION CONTEXT (User Intent)
           - Extract the real problem being solved
           - Identify success criteria (explicit or implied)
           - Understand urgency and timeline drivers
           - Capture user goals and pain points

        Based on this contextual analysis:
        - If you have enough details, generate a context-aware PRD in JSON format
        - If you need more information, ask questions that fill specific context gaps

        IMPORTANT RULES:
        - Use terminology from the actual conversation, not generic templates
        - NEVER make up URLs, links, or specific endpoints
        - Only include actual links/URLs if the user explicitly provides them
        - For design/documentation sections, use "status": "pending" and suggest what would be helpful
        - Do not hallucinate API endpoints - describe what APIs are needed conceptually
        - ADAPT the structure to the inferred domain - let context drive structure
        - Generate domain-specific fields based on what's discussed
        - CRITICAL: Ensure all JSON strings are properly escaped
        - Never use single quotes or apostrophes in JSON values
        - Use double quotes for all JSON strings
        - TIMELINE RULES:
          * All dates must be in 2025 or later
          * Use realistic timeframes (Q1 2025, Q2 2025, etc.)
          * Consider current date is \(Date().formatted(.dateTime.year().month(.abbreviated)))
          * Never use past dates like Q3 2023
          * For metrics timeframes, use relative terms like "90 days", "6 months" or future quarters

        CONTEXT ASSEMBLY STRATEGY:
        Apply dynamic context engineering - gather and organize all relevant details from the conversation.

        REASONING APPROACH:
        Apply chain-of-thought reasoning:
        1. What is being built? → Understand the core system
        2. Who will use the output? → Understand the audience
        3. What do they need to succeed? → Determine necessary content
        4. What would validate success? → Define acceptance criteria
        5. What examples would help? → Create relevant test data

        SELF-CONSISTENCY:
        The structure you generate should logically follow from your reasoning.
        Each section should exist because reasoning determined it's needed.
        Content should be what reasoning concluded is necessary.

        OUTPUT PRINCIPLES:
        - No templates - structure emerges from understanding
        - Concrete over abstract - real examples, not placeholders
        - Context determines content - what makes sense HERE
        - Complete implementation guide - any AI can build from this

        COMPLETENESS CHECK:
        Ask yourself: Can someone implement this without asking questions?
        If not, what's missing? Add it.

        CONCRETENESS CHECK:
        Are there placeholders or vague descriptions?
        Replace them with actual, specific content.

        CONTEXT CHECK:
        Does every part make sense for what's being built?
        Remove what doesn't fit, add what's missing.
        
        IMPORTANT: Only mark as incomplete if you truly cannot proceed.
        If you have enough context to create a working PRD, create it.

        If genuinely incomplete, provide specific, actionable questions:
        {
          "status": "incomplete",
          "gathered_so_far": "specific summary of understood requirements",
          "still_needed": ["specific missing information"],
          "questions": ["specific questions that would unblock progress"]
        }
        \(fallbackGuidance)
        """
        
        do {
            let contextAwareSystemPrompt = """
            You are an expert at understanding requirements and generating implementation-ready specifications.

            CONTEXT ENGINEERING FRAMEWORK:
            1. Assemble context dynamically from the conversation
            2. Use chain-of-thought reasoning to understand the true intent
            3. Apply self-consistency checks - does the output make logical sense?
            4. Prune conflicting information, keep what's relevant

            REASONING PROCESS:
            Think deeply about:
            - What problem is being solved?
            - Who needs this solution?
            - What would success look like?
            - What information would someone need to create this?

            Let your understanding shape the output structure.
            Don't force any particular format.

            OUTPUT PHILOSOPHY:
            Structure emerges from understanding, not from templates.
            Content is determined by context, not by patterns.
            Examples are concrete and specific to this request.
            """

            let (response, _) = try await orchestrator.sendMessage(
                prompt,
                systemPrompt: contextAwareSystemPrompt,
                needsJSON: true
            )
            
            // Clean the response - remove markdown code blocks if present
            let cleanedResponse = cleanJSONResponse(response)
            
            
            // Check if we have a complete PRD (not incomplete status)
            if !cleanedResponse.contains("\"status\": \"incomplete\"") {
                // Generate test data and acceptance criteria separately
                do {
                    // Generate test data based on actual PRD content
                    let testData = try await generateTestData(for: cleanedResponse, orchestrator: orchestrator)

                    // Generate acceptance criteria based on actual PRD content
                    let acceptanceCriteria = try await generateAcceptanceCriteria(for: cleanedResponse, orchestrator: orchestrator)
                    
                    // Combine everything into the final response
                    var finalResponse = cleanedResponse
                    
                    // Insert test data and acceptance criteria before the closing brace
                    if let lastBrace = finalResponse.lastIndex(of: "}") {
                        let insertPosition = finalResponse.index(before: lastBrace)
                        
                        // Add test data if we got it
                        if let testDataJSON = extractJSONObject(from: testData, key: "test_data") {
                            let testDataString = ",\n  \"test_data\": \(testDataJSON)"
                            finalResponse.insert(contentsOf: testDataString, at: insertPosition)
                        }
                        
                        // Add acceptance criteria if we got it
                        if let criteriaJSON = extractJSONObject(from: acceptanceCriteria, key: "acceptance_criteria") {
                            let criteriaString = ",\n  \"acceptance_criteria\": \(criteriaJSON)"
                            finalResponse.insert(contentsOf: criteriaString, at: insertPosition)
                        }
                    }
                    
                    return finalResponse
                } catch {
                    // If we fail to generate test data or criteria, return the original PRD
                    print("Note: Could not generate test data or acceptance criteria")
                    return cleanedResponse
                }
            }
            
            return cleanedResponse
        } catch {
            throw error
        }
    }
    
    /// Extract a specific JSON object/array from a JSON string
    private static func extractJSONObject(from json: String, key: String) -> String? {
        guard let data = json.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let object = parsed[key] else {
            return nil
        }
        
        // Convert back to JSON string
        if let objectData = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted),
           let objectString = String(data: objectData, encoding: .utf8) {
            return objectString
        }
        
        return nil
    }
    
    /// Convert final PRD to GitHub issue format
    public static func formatForGitHub(prd: String) -> String {
        // Try to parse JSON to extract design/doc links
        var designSection = ""
        var docSection = ""
        
        if let data = prd.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            // Extract design mockups
            if let design = json["design"] as? [String: Any],
               let mockups = design["mockups"] as? [[String: String]] {
                designSection = "\n### 🎨 Design Resources\n"
                for mockup in mockups {
                    if let tool = mockup["tool"], let url = mockup["url"], let desc = mockup["description"] {
                        designSection += "- [\(tool): \(desc)](\(url))\n"
                    }
                }
            }
            
            // Extract documentation
            if let docs = json["documentation"] as? [String: Any],
               let refs = docs["references"] as? [[String: String]] {
                docSection = "\n### 📚 Documentation\n"
                for ref in refs {
                    if let type = ref["type"], let url = ref["url"], let desc = ref["description"] {
                        docSection += "- [\(type): \(desc)](\(url))\n"
                    }
                }
            }
        }
        
        return """
        ## 📋 Product Requirements Document
        
        ```json
        \(prd)
        ```
        \(designSection)\(docSection)
        ---
        
        ### Implementation Checklist
        - [ ] Review requirements
        - [ ] Review design mockups
        - [ ] Technical design
        - [ ] Implementation
        - [ ] Testing
        - [ ] Documentation
        - [ ] Accessibility audit
        - [ ] Deploy
        
        ### Labels
        `feature` `needs-review` `prd` `has-designs`
        """
    }
    
    /// Convert final PRD to JIRA format
    public static func formatForJira(prd: String) -> String {
        return """
        h1. Product Requirements Document
        
        {code:json}
        \(prd)
        {code}
        
        h2. Definition of Done
        * All acceptance criteria met
        * Code reviewed and approved
        * Tests written and passing
        * Documentation updated
        """
    }
    
    // MARK: - Helper Methods
    
    /// Validate and fix timeline strings to ensure they're in the future
    public static func validateTimeline(_ timeline: String) -> String {
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentQuarter = (Calendar.current.component(.month, from: Date()) - 1) / 3 + 1
        
        // Check for outdated quarter references
        if timeline.contains("Q") && timeline.contains("20") {
            // Extract year from timeline
            if let yearMatch = timeline.range(of: "20\\d{2}", options: .regularExpression),
               let year = Int(timeline[yearMatch]) {
                if year < currentYear {
                    // Replace with next quarter
                    let nextQuarter = currentQuarter == 4 ? 1 : currentQuarter + 1
                    let nextYear = currentQuarter == 4 ? currentYear + 1 : currentYear
                    return timeline.replacingOccurrences(of: String(timeline[yearMatch]), 
                                                        with: "Q\(nextQuarter) \(nextYear)")
                } else if year == currentYear {
                    // Check if quarter is in the past
                    if let quarterMatch = timeline.range(of: "Q[1-4]", options: .regularExpression),
                       let quarter = Int(String(timeline[quarterMatch].dropFirst())) {
                        if quarter <= currentQuarter {
                            // Move to next available quarter
                            let nextQuarter = currentQuarter == 4 ? 1 : currentQuarter + 1
                            let nextYear = currentQuarter == 4 ? currentYear + 1 : currentYear
                            return "Q\(nextQuarter) \(nextYear)"
                        }
                    }
                }
            }
        }
        
        // Check for any year reference that's outdated
        if let yearMatch = timeline.range(of: "20\\d{2}", options: .regularExpression),
           let year = Int(timeline[yearMatch]),
           year < currentYear {
            return timeline.replacingOccurrences(of: String(timeline[yearMatch]), 
                                                with: String(currentYear + 1))
        }
        
        return timeline
    }
    
    /// Build glossary context for the prompt
    private static func buildGlossaryContext(_ glossary: Glossary) async -> String {
        let entries = glossary.list()
        if entries.isEmpty {
            return ""
        }
        
        let glossaryText = entries.map { "\($0.acronym): \($0.definition)" }.joined(separator: ", ")
        return "Glossary context: \(glossaryText)"
    }
    
    /// Extract test data from PRD JSON response
    public static func extractTestData(from prdJSON: String) -> TestDataDefinition? {
        guard let data = prdJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let testDataSection = json["test_data"] as? [String: Any] else {
            return nil
        }
        
        // Convert the test_data section to TestDataDefinition
        do {
            let testDataJSON = try JSONSerialization.data(withJSONObject: testDataSection)
            return try JSONDecoder().decode(TestDataDefinition.self, from: testDataJSON)
        } catch {
            print("Failed to decode test data: \(error)")
            return nil
        }
    }
    
    /// Extract acceptance criteria from PRD JSON response
    public static func extractAcceptanceCriteria(from prdJSON: String) -> [AcceptanceCriterion]? {
        guard let data = prdJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let criteriaSection = json["acceptance_criteria"] as? [[String: Any]] else {
            return nil
        }
        
        // Convert to AcceptanceCriterion objects
        do {
            let criteriaJSON = try JSONSerialization.data(withJSONObject: criteriaSection)
            return try JSONDecoder().decode([AcceptanceCriterion].self, from: criteriaJSON)
        } catch {
            print("Failed to decode acceptance criteria: \(error)")
            return nil
        }
    }
    
    /// Generate executable tests from PRD
    public static func generateTestsFromPRD(_ prd: String) -> String {
        var result = "// Generated Tests from PRD\n\n"
        
        // Extract test data
        if let testData = extractTestData(from: prd) {
            result += TestDataManager.generateSwiftTests(from: testData.scenarios)
            result += "\n\n"
        }
        
        // Extract acceptance criteria and convert to tests
        if let criteria = extractAcceptanceCriteria(from: prd) {
            result += "// Tests from Acceptance Criteria\n\n"
            result += AcceptanceCriteriaManager.convertToTestCases(criteria)
        }
        
        return result
    }
    
    /// Generate test data for a PRD after it's been created
    public static func generateTestData(
        for prd: String,
        orchestrator: Orchestrator
    ) async throws -> String {

        // Based on 2025 research: Statistical Pattern Preservation + Real-time Generation
        let prompt = """
        Analyze this PRD and generate comprehensive test data using modern testing patterns:

        PRD Content:
        \(prd)

        Apply these domain-agnostic test generation techniques:

        1. STATISTICAL PATTERN PRESERVATION
           - Extract entities and their relationships from the PRD
           - Maintain realistic data distributions
           - Preserve referential integrity between data points
           - Generate statistically valid test sets

        2. SCENARIO GENERATION (based on actual PRD content)
           - Happy path: Test each feature's successful operation
           - Edge cases: Boundary conditions for each constraint mentioned
           - Error scenarios: Invalid inputs for each validation rule
           - Performance boundaries: Stress test data for scalability requirements
           - Security scenarios: Test authentication, authorization, data protection

        3. DATA SET GENERATION
           For each entity/feature in the PRD, create:
           - Valid data sets: Realistic data matching production patterns
           - Invalid data sets: Test validation rules
           - Boundary data sets: Min/max values, empty sets, nulls
           - Volume data sets: For performance testing

        4. SYNTHETIC DATA REQUIREMENTS
           - Privacy-compliant: No real user data
           - Realistic: Matches actual usage patterns
           - Diverse: Covers all user personas mentioned
           - Repeatable: Deterministic generation for CI/CD

        Generate test data that:
        - Directly maps to each requirement in the PRD
        - Uses domain terminology from the PRD (not generic examples)
        - Includes concrete values, not placeholders
        - Covers all user workflows described
        - Tests all integration points mentioned

        REASONING ABOUT TEST DATA:
        Apply chain-of-thought: What does "test data" mean for THIS specific PRD?
        - For a PRD generator: examples of PRDs it would output
        - For an API: request/response examples
        - For a UI: user interaction scenarios

        Let context and reasoning determine what test data should be.
        Structure emerges from understanding the actual need.
        """
        
        let (response, _) = try await orchestrator.sendMessage(
            prompt,
            systemPrompt: """
            You are a test data generation expert using modern 2025 best practices.

            Apply these principles:
            - Statistical Pattern Preservation: Maintain realistic data distributions
            - Domain inference from PRD content, not generic templates
            - Privacy-compliant synthetic data generation
            - Scenario-based test data covering all PRD requirements

            Generate test data that directly reflects the actual PRD content.
            """,
            needsJSON: true
        )
        
        return cleanJSONResponse(response)
    }
    
    /// Generate acceptance criteria for a PRD after it's been created
    public static func generateAcceptanceCriteria(
        for prd: String,
        orchestrator: Orchestrator
    ) async throws -> String {

        // Based on 2025 research: BDD/Gherkin patterns for domain-agnostic acceptance criteria
        let prompt = """
        Analyze this PRD and generate comprehensive acceptance criteria using BDD best practices:

        PRD Content:
        \(prd)

        Apply Gherkin Given-When-Then patterns with these guidelines:

        1. SCENARIO COVERAGE
           For each feature/capability in the PRD:
           - Normal flow scenarios (happy path)
           - Alternative flows
           - Exception/error scenarios
           - Boundary conditions
           - Performance criteria

        2. STAKEHOLDER PERSPECTIVES
           For each user role/persona mentioned:
           - User journey acceptance criteria
           - Role-based access scenarios
           - Usability criteria
           - Accessibility requirements

        3. INTEGRATION POINTS
           For each external system/API mentioned:
           - Integration success scenarios
           - Failure handling
           - Data consistency checks
           - Performance/timeout handling

        4. BDD STRUCTURE
           Each criterion must follow:
           - Scenario: Descriptive business-readable name
           - Given: State of the world before the behavior (preconditions)
           - When: The behavior being specified (action)
           - Then: Observable consequences (outcomes)
           - And/But: Additional steps when needed

        5. QUALITY ATTRIBUTES
           - Business-readable: Use domain language from PRD
           - Testable: Concrete, measurable outcomes
           - Independent: Each scenario standalone
           - Complete: Cover all PRD requirements

        Generate criteria that:
        - Map directly to PRD requirements (reference requirement IDs)
        - Use exact terminology from the PRD
        - Include concrete examples and data
        - Are implementation-agnostic but behavior-specific
        - Cover functional and non-functional requirements

        Output as JSON:
        {
          "acceptance_criteria": [
            {
              "scenario": "descriptive name from PRD feature",
              "requirement_ref": "PRD section/requirement it validates",
              "given": "specific preconditions",
              "when": "user/system action",
              "then": "measurable outcome",
              "priority": "must-have|should-have|nice-to-have",
              "tags": ["functional", "integration", "performance", etc.]
            }
          ]
        }
        """
        
        let (response, _) = try await orchestrator.sendMessage(
            prompt,
            systemPrompt: """
            You are a BDD expert specializing in context-aware acceptance criteria.

            Apply these 2025 best practices:
            - Use Gherkin Given-When-Then patterns adapted to the domain
            - Extract domain context from PRD, not generic templates
            - Create scenarios that directly validate PRD requirements
            - Ensure business-readable yet technically precise criteria

            Generate acceptance criteria specific to the actual PRD content.
            """,
            needsJSON: true
        )
        
        return cleanJSONResponse(response)
    }
    
    /// Let AI suggest appropriate metrics for ANY domain
    public static func generateMetricsPrompt(for feature: String, context: String) -> String {
        return """
        For this requirement: \(feature)
        Context: \(context)
        
        Suggest appropriate success metrics for this specific domain.
        Consider what would actually matter for measuring success.
        
        Output metrics as JSON array:
        [
          {
            "name": "specific metric name",
            "unit": "appropriate unit of measurement",
            "baseline": "current state if known",
            "target": "desired outcome",
            "timeframe": "when to achieve",
            "rationale": "why this metric matters"
          }
        ]
        
        Examples:
        - For software: response time (ms), error rate (%), uptime (%)
        - For medical: efficacy rate (%), symptom reduction (scale), adverse events (count)
        - For business: revenue ($), customer acquisition (count), churn rate (%)
        - For research: publication count, citation impact, reproducibility (%)
        
        Be domain-appropriate. Don't force software metrics on non-software projects.
        """
    }
}