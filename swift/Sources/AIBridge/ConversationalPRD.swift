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
        
        // Detect domain and get intelligent guidance
        let domain = DomainKnowledge.detectDomain(from: initialRequest)
        let domainGuidance = DomainKnowledge.getDomainGuidance(for: domain, request: initialRequest)
        let domainQuestions = DomainKnowledge.generateDomainQuestions(domain: domain, context: initialRequest)
        
        // Get relevant acronyms from glossary
        let glossary = orchestrator.glossaryForCurrentSession()
        let glossaryContext = await buildGlossaryContext(glossary)
        
        // First, understand what the user wants
        // Create domain questions JSON array safely with proper escaping
        let escapedQuestions = domainQuestions.map { escapeForJSON($0) }
        let domainQuestionsJSON = escapedQuestions.isEmpty ? "[]" : 
            "[\n    \"" + escapedQuestions.joined(separator: "\",\n    \"") + "\"\n  ]"
        
        let analysisPrompt = """
        User wants to build: \(initialRequest)
        
        \(domainGuidance)
        
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
          "domain": "\(domain)",
          "clear_requirements": ["what is already specified"],
          "questions": [
            "specific question 1", 
            "specific question 2"
          ],
          "domain_questions": \(domainQuestionsJSON),
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
        
        // After 5 attempts, use domain-specific questions as fallback
        let domain = DomainKnowledge.detectDomain(from: originalRequest)
        let domainQuestions = attemptNumber >= 5 ? 
            DomainKnowledge.generateDomainQuestions(domain: domain, context: originalRequest) : []
        
        let fallbackGuidance = attemptNumber >= 5 ? """
        
        IMPORTANT: This is attempt #\(attemptNumber). If you still don't have enough information, 
        prioritize asking these domain-specific questions that haven't been answered yet:
        \(domainQuestions.joined(separator: "\n"))
        """ : ""
        
        let prompt = """
        Building PRD for: \(originalRequest)
        
        Previous context: \(previousContext)
        User provided: \(userResponse)
        
        Based on this new information:
        - If you have enough details, generate a complete PRD in JSON/YAML format
        - If you need more information, ask the next most important questions
        
        IMPORTANT RULES:
        - NEVER make up URLs, links, or specific endpoints
        - Only include actual links/URLs if the user explicitly provides them
        - For design/documentation sections, use "status": "pending" and suggest what would be helpful
        - Do not hallucinate API endpoints - describe what APIs are needed conceptually
        - ADAPT the structure to the domain - do not force software patterns on non-software projects
        - CRITICAL: Ensure all JSON strings are properly escaped
        - Never use single quotes or apostrophes in JSON values
        - Use double quotes for all JSON strings
        - TIMELINE RULES: 
          * All dates must be in 2025 or later
          * Use realistic timeframes (Q1 2025, Q2 2025, etc.)
          * Consider current date is \(Date().formatted(.dateTime.year().month(.abbreviated)))
          * Never use past dates like Q3 2023
          * For metrics timeframes, use relative terms like "90 days", "6 months" or future quarters
        
        Create a PRD structure appropriate for the domain.
        
        For SOFTWARE/TECH:
        {
          "title": "feature name",
          "problem": "what problem this solves",
          "solution": {
            "overview": "high-level approach",
            "technical_details": "specific implementation details",
            "components": ["list of components to build"]
          },
          "design": {
            "status": "pending|provided|not_needed",
            "mockups": [
              // Only include if user provides actual links
              // {"tool": "Figma", "url": "actual_url_from_user", "description": "what it shows"}
            ],
            "recommendations": ["Consider creating wireframes", "UI mockups would help clarify requirements"]
          },
          "documentation": {
            "status": "pending|provided|not_needed",
            "references": [
              // Only include if user provides actual links
              // {"type": "Confluence", "url": "actual_url_from_user", "description": "what it contains"}
            ],
            "recommendations": ["Document API contracts", "Create architecture diagrams"]
          },
          "requirements": {
            "functional": ["what it must do"],
            "technical": ["how it must work"],
            "security": ["security requirements"],
            "accessibility": ["WCAG 2.1 AA requirements"]
          },
          "tasks": ["ordered implementation tasks"],
          "success_metrics": [
            {"name": "metric", "unit": "percent|ms|count", "baseline": "current", "target": "goal", "timeframe": "when"}
          ],
          "risks": ["potential issues and mitigations"],
          "resources": {
            "team": ["who's involved"],
            "timeline": "estimated completion",
            "dependencies": ["external dependencies"]
          }
        }
        
        For MEDICAL/PHARMA:
        {
          "title": "treatment/study name",
          "condition": "what condition is being addressed",
          "patient_population": "who this is for",
          "mechanism_of_action": "how it works",
          "clinical_approach": {
            "trial_design": "study structure",
            "endpoints": ["primary", "secondary outcomes"],
            "safety_monitoring": "adverse event tracking"
          },
          "regulatory_requirements": ["FDA", "EMA", "other"],
          "success_metrics": ["efficacy measures", "safety profile"],
          "timeline": "development phases"
        }
        
        For BUSINESS/OPERATIONS:
        {
          "title": "initiative name",
          "business_case": "why this matters",
          "current_state": "as-is situation",
          "future_state": "to-be vision",
          "implementation": {
            "workstreams": ["parallel efforts"],
            "stakeholders": ["who's affected"],
            "change_management": "adoption strategy"
          },
          "success_metrics": ["KPIs", "OKRs"],
          "risks": ["business risks", "mitigations"]
        }
        
        ADAPT TO THE ACTUAL DOMAIN - these are just examples.
        
        If more info needed, respond with:
        {
          "status": "incomplete",
          "gathered_so_far": "summary of what we know",
          "still_needed": ["what's still missing"],
          "questions": ["next questions to ask"]
        }
        \(fallbackGuidance)
        """
        
        do {
            let (response, _) = try await orchestrator.sendMessage(
                prompt,
                systemPrompt: "You are a technical product manager. Be specific and thorough.",
                needsJSON: true
            )
            
            // Clean the response - remove markdown code blocks if present
            let cleanedResponse = cleanJSONResponse(response)
            
            
            // Check if we have a complete PRD (not incomplete status)
            if !cleanedResponse.contains("\"status\": \"incomplete\"") {
                // Generate test data and acceptance criteria separately
                do {
                    // Extract domain from the original request
                    let domain = DomainKnowledge.detectDomain(from: originalRequest)
                    
                    // Generate test data
                    let testData = try await generateTestData(for: cleanedResponse, domain: domain, orchestrator: orchestrator)
                    
                    // Generate acceptance criteria
                    let acceptanceCriteria = try await generateAcceptanceCriteria(for: cleanedResponse, domain: domain, orchestrator: orchestrator)
                    
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
    private static func buildGlossaryContext(_ glossary: DomainGlossary) async -> String {
        let entries = await glossary.list()
        if entries.isEmpty {
            return ""
        }
        
        let glossaryText = entries.map { "\($0.acronym): \($0.expansion)" }.joined(separator: ", ")
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
        domain: String,
        orchestrator: Orchestrator
    ) async throws -> String {
        
        let prompt = """
        Based on this PRD, generate comprehensive test data:
        
        PRD Summary: \(String(prd.prefix(1000)))
        Domain: \(domain)
        
        Generate test scenarios and data sets as JSON:
        {
          "test_data": {
            "scenarios": [
              {
                "id": "test-1",
                "name": "Valid payment test",
                "description": "Test successful payment",
                "priority": "critical",
                "steps": [
                  {
                    "action": "Enter valid card details",
                    "data": {},
                    "validation": "Card accepted"
                  }
                ],
                "expected_results": ["Payment processed"]
              }
            ],
            "data_sets": {
              "valid": {"name": "Valid", "type": "valid", "values": {}},
              "invalid": {"name": "Invalid", "type": "invalid", "values": {}},
              "boundary": {"name": "Boundary", "type": "boundary", "values": {}}
            }
          }
        }
        """
        
        let (response, _) = try await orchestrator.sendMessage(
            prompt,
            systemPrompt: "Generate comprehensive test data for the PRD.",
            needsJSON: true
        )
        
        return cleanJSONResponse(response)
    }
    
    /// Generate acceptance criteria for a PRD after it's been created
    public static func generateAcceptanceCriteria(
        for prd: String,
        domain: String,
        orchestrator: Orchestrator
    ) async throws -> String {
        
        let prompt = """
        Based on this PRD, generate acceptance criteria:
        
        PRD Summary: \(String(prd.prefix(1000)))
        Domain: \(domain)
        
        Generate acceptance criteria in Given-When-Then format as JSON:
        {
          "acceptance_criteria": [
            {
              "given": "User has valid payment card",
              "when": "User submits payment form",
              "then": "Payment is processed successfully",
              "priority": "must-have"
            }
          ]
        }
        """
        
        let (response, _) = try await orchestrator.sendMessage(
            prompt,
            systemPrompt: "Generate acceptance criteria for the PRD.",
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