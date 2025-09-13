import Foundation

public enum SystemContextBuilder {
    public static func buildFixedContext(persona: PersonaProfile) -> String {
        var lines: [String] = []
        lines.append("In this orchestrator, PRD always means Product Requirements Document.")
        lines.append("Assume enterprise IT context unless otherwise specified.")
        lines.append("Always include quantifiable metrics, P0/P1 priorities, and ROI explanations.")
        lines.append("Persona: \(persona.name) | Availability SLO: \(String(format: "%.2f", persona.availabilitySLO))% | Latency sensitivity p95: \(persona.latencySensitivityMs) ms | Security emphasis: \(persona.securityEmphasis ? "high" : "standard").")
        return lines.joined(separator: " ")
    }

    public static func buildRewriteInstruction(persona: PersonaProfile) -> String {
        return """
        Rewrite the above answer to:
        - Inject concrete, quantifiable metrics (percentages, ms, req/s, dates).
        - Add explicit priority tags (P0 for must-have, P1 for should-have).
        - Include ROI explanation with numbers (e.g., $ impact, payback period).
        - Align with persona constraints: availability ≥ \(String(format: "%.2f", persona.availabilitySLO))%, p95 ≤ \(persona.latencySensitivityMs) ms, security emphasis: \(persona.securityEmphasis ? "compliance-heavy" : "standard").
        Keep the structure and improve specificity. Do not remove technical details.
        """
    }
}
