import Foundation

/// Simple conversational PRD builder
/// Manages the conversation loop to build structured requirements
public struct ConversationalPRD {
    
    /// Start a PRD conversation
    public static func startConversation(
        initialRequest: String,
        orchestrator: Orchestrator
    ) async throws -> String {
        
        // First, understand what the user wants
        let analysisPrompt = """
        User wants to build: \(initialRequest)
        
        Analyze this request and respond with:
        1. Your understanding of what needs to be built
        2. Critical questions to create a complete specification
        3. What information is already clear vs what's missing
        
        Output as JSON:
        {
          "understanding": "what you understand",
          "domain": "payment|auth|search|feature|etc",
          "clear_requirements": ["what's already specified"],
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
            "needs_ui": "boolean - does this need UI design?",
            "needs_docs": "boolean - would benefit from documentation?"
          }
        }
        """
        
        let (analysis, _) = try await orchestrator.sendMessage(
            analysisPrompt,
            systemPrompt: "You are a technical product manager helping to create detailed specifications.",
            needsJSON: true
        )
        
        return analysis
    }
    
    /// Continue building the PRD with new information
    public static func continueConversation(
        originalRequest: String,
        previousContext: String,
        userResponse: String,
        orchestrator: Orchestrator
    ) async throws -> String {
        
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
        - Don't hallucinate API endpoints - describe what APIs are needed conceptually
        
        For a complete PRD, include:
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
          "acceptance_criteria": ["measurable success criteria"],
          "risks": ["potential issues and mitigations"],
          "resources": {
            "team": ["who's involved"],
            "timeline": "estimated completion",
            "dependencies": ["external dependencies"]
          }
        }
        
        If more info needed, respond with:
        {
          "status": "incomplete",
          "gathered_so_far": "summary of what we know",
          "still_needed": ["what's still missing"],
          "questions": ["next questions to ask"]
        }
        """
        
        let (response, _) = try await orchestrator.sendMessage(
            prompt,
            systemPrompt: "You are a technical product manager. Be specific and thorough.",
            needsJSON: true
        )
        
        return response
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
}