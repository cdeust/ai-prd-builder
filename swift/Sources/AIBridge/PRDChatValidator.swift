import Foundation

public struct PRDChatValidatorResult {
    public let hasQuantMetrics: Bool
    public let hasPriorities: Bool
    public let hasROI: Bool

    public var isValid: Bool { hasQuantMetrics && hasPriorities && hasROI }
}

public enum PRDChatValidator {
    public static func validate(_ text: String) -> PRDChatValidatorResult {
        // Quantifiable metrics: numbers with units like %, ms, req/s, dates
        let hasPercent = text.range(of: #"\d+(\.\d+)?\s*%"#, options: .regularExpression) != nil
        let hasMs = text.range(of: #"\d+(\.\d+)?\s*ms"#, options: .regularExpression) != nil
        let hasReqS = text.range(of: #"\d+(\.\d+)?\s*(req/s|rps|requests/sec)"#, options: [.regularExpression, .caseInsensitive]) != nil
        let hasDate = text.range(of: #"\b\d{4}-\d{2}-\d{2}\b"#, options: .regularExpression) != nil
        let hasQuantMetrics = hasPercent || hasMs || hasReqS || hasDate

        // Priorities: P0 or P1 tokens (use word boundaries to avoid false positives)
        let hasPriorities = text.range(of: #"\bP[01]\b"#, options: [.regularExpression, .caseInsensitive]) != nil

        // ROI mentions: $, ROI, payback, savings, cost reduction
        let hasDollar = text.contains("$")
        let hasROIWord = text.range(of: #"\broi\b"#, options: [.regularExpression, .caseInsensitive]) != nil
        let hasPayback = text.range(of: #"\bpayback\b"#, options: [.regularExpression, .caseInsensitive]) != nil
        let hasSavings = text.range(of: #"\bsavings?\b"#, options: [.regularExpression, .caseInsensitive]) != nil
        let hasCostReduction = text.range(of: #"\bcost reduction\b"#, options: [.regularExpression, .caseInsensitive]) != nil
        let hasROI = hasDollar || hasROIWord || hasPayback || hasSavings || hasCostReduction

        return PRDChatValidatorResult(
            hasQuantMetrics: hasQuantMetrics,
            hasPriorities: hasPriorities,
            hasROI: hasROI
        )
    }

    public static func buildCorrectionPrompt(missing result: PRDChatValidatorResult, persona: PersonaProfile) -> String {
        var asks: [String] = []
        if !result.hasQuantMetrics {
            asks.append("Add concrete, quantifiable metrics (%, ms, req/s, and dates).")
        }
        if !result.hasPriorities {
            asks.append("Label items with P0/P1 priorities (P0=must-have, P1=should-have).")
        }
        if !result.hasROI {
            asks.append("Add ROI rationale with numeric estimates (e.g., $/month impact, payback period).")
        }
        let personaLine = "Respect persona constraints: availability ≥ \(String(format: "%.2f", persona.availabilitySLO))%, p95 ≤ \(persona.latencySensitivityMs) ms, security emphasis: \(persona.securityEmphasis ? "compliance-heavy" : "standard")."
        return """
        Improve the previous answer to address the following:
        - \(asks.joined(separator: "\n- "))
        \(personaLine)
        Keep the existing structure and content; only add the missing details.
        """
    }
}
