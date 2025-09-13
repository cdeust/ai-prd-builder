import Foundation

public enum SMARTMetricsSynthesizer {
    public static func synthesize(
        feature: String,
        context: String,
        requirements: [String],
        persona: PersonaProfile,
        hardware: HardwareProfile,
        timelineHint: String? = nil
    ) -> [String] {
        var out: [String] = []
        
        // Performance (anchor to hardware)
        out.append("Performance (p95): < \(hardware.expectedP95LatencyMs) ms on \(hardware.cpuTier)")
        out.append("Throughput: ≥ \(hardware.throughputGuidance) req/s sustained")
        
        // Availability (persona-driven, not below hardware floor)
        let availability = max(persona.availabilitySLO, hardware.availabilityFloor)
        out.append(String(format: "Availability (monthly): ≥ %.2f%%", availability))
        
        // Quality
        out.append("Error rate: < 0.1% over rolling 7 days")
        out.append("Test coverage: ≥ 85% lines, ≥ 70% branches")
        
        // Security/Compliance
        if persona.securityEmphasis {
            out.append("Security: 0 critical vulnerabilities at release; SOC2 controls mapped; PII encrypted at rest (AES‑256) and in transit (TLS 1.3)")
        } else {
            out.append("Security: 0 critical vulnerabilities at release; PII encrypted at rest and in transit")
        }
        
        // Adoption targets (persona aggressiveness)
        let baseDAU = 1000
        let dau = baseDAU * max(1, persona.adoptionAggressiveness)
        out.append("Adoption: ≥ \(dau) DAUs by \(timelineHint ?? "end of quarter")")
        
        // Operational metrics
        out.append("MTTR: < 30 minutes; change failure rate < 10%")
        
        // Context-sensitive adds (simple heuristics)
        let text = "\(feature) \(context) \(requirements.joined(separator: " "))".lowercased()
        if text.contains("api") || text.contains("service") {
            out.append("API p95: < \(max(100, persona.latencySensitivityMs)) ms; p99 < \(max(200, persona.latencySensitivityMs + 100)) ms")
        }
        if text.contains("ml") || text.contains("ai") || text.contains("inference") {
            out.append("Inference p95: < \(hardware.expectedP95LatencyMs) ms on \(hardware.cpuTier); batch throughput ≥ \(max(100, hardware.throughputGuidance/10)) ops/s")
        }
        
        return out
    }
}
