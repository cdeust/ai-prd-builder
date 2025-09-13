import Foundation
import AIProviders

public enum PRDMessageBuilder {
    public static func build(
        feature: String,
        context: String,
        priority: String,
        requirements: [String],
        includeHistory: Bool = false,
        history: [ChatMessage] = [],
        glossaryPolicy: String = ""
    ) -> [ChatMessage] {
        let systemPrompt = """
        You are a senior technical product manager creating production-ready PRDs.
        
        Your PRDs must be:
        1. **Comprehensive**: Cover all aspects from problem to deployment
        2. **Specific**: Use exact numbers, dates, and metrics (no vague terms)
        3. **Technical**: Include API specs, data models, and architecture
        4. **Actionable**: Clear acceptance criteria and implementation steps
        5. **Measurable**: Quantified success metrics and KPIs
        
        Structure:
        - Executive Summary (with quantified problem/solution)
        - Functional Requirements (with priorities)
        - Technical Specification (APIs, database, security)
        - Acceptance Criteria (GIVEN-WHEN-THEN format)
        - Success Metrics (baseline → target)
        - Implementation Plan (phased delivery)
        - Risks & Mitigation (with probabilities)
        
        Focus on developer-readiness and immediate actionability.
        """
        
        let userPrompt = """
        Create a comprehensive PRD for:
        
        **Feature:** \(feature)
        **Context:** \(context)
        **Priority:** \(priority)
        **Requirements:**
        \(requirements.map { "- \($0)" }.joined(separator: "\n"))
        
        Include an “Assumptions & Acronyms” section that lists any acronyms used with their expansions per the session glossary.
        The PRD must be production-ready with:
        - Specific technical specifications
        - Clear API endpoint definitions
        - Database schema if applicable
        - Measurable acceptance criteria
        - Quantified success metrics
        - Realistic timeline with phases
        - Risk assessment with mitigation
        
        Make it immediately actionable for developers.
        """
        
        var messages = [ChatMessage(role: .system, content: systemPrompt + (glossaryPolicy.isEmpty ? "" : "\n" + glossaryPolicy))]
        
        if includeHistory {
            messages.append(contentsOf: history.suffix(5))
        }
        
        messages.append(ChatMessage(role: .user, content: userPrompt))
        return messages
    }
}
