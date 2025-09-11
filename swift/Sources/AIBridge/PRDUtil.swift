import Foundation

// MARK: - PRD Utilities (Generic, Domain-Agnostic)

public enum PRDUtil {
    
    // MARK: - JSON Safe Decode/Repair
    
    /// Safe JSON decode that handles malformed JSON by finding last block and balancing braces
    public static func safeJSONDecode<T: Decodable>(_ raw: String, as type: T.Type) -> T? {
        // Try to pick the last {...} block if multiple
        let candidates = raw.matches(of: #"\{[\s\S]*\}"#)
        guard var text = candidates.last else { return nil }
        
        // Balance braces roughly
        let openCount = text.filter { $0 == "{" }.count
        let closeCount = text.filter { $0 == "}" }.count
        if closeCount < openCount {
            text += String(repeating: "}", count: openCount - closeCount)
        }
        
        guard let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    // MARK: - Metrics Normalization
    
    /// Normalize metrics ensuring all fields are filled with sensible defaults
    public static func normalizeMetrics(_ items: [Metric]) -> [Metric] {
        return items.compactMap { m in
            var unit = m.unit.trimmingCharacters(in: .whitespacesAndNewlines)
            var baseline = m.baseline.trimmingCharacters(in: .whitespacesAndNewlines)
            var target = m.target.trimmingCharacters(in: .whitespacesAndNewlines)
            var timeframe = m.timeframe.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if unit.isEmpty { unit = "count" }
            if baseline.isEmpty { baseline = "0" }
            if target.isEmpty { target = "1" }
            if timeframe.isEmpty { timeframe = "by launch" }
            
            // Enrich boolean-ish targets to percentages
            if (target == "1" || target.lowercased() == "true") {
                unit = "percent"
                target = "100"
                if baseline == "0" || baseline.lowercased() == "false" { baseline = "0" }
            }
            
            return Metric(
                name: m.name,
                unit: unit,
                baseline: baseline,
                target: target,
                timeframe: timeframe
            )
        }
    }
    
    // MARK: - Timeline Normalization
    
    /// Normalize timeline from hints like "Q3 2025" or "12 weeks"
    public static func normalizeTimeline(hint: String, today: Date = Date()) -> TimelineWindow {
        let cal = Calendar(identifier: .iso8601)
        let now = cal.dateComponents([.year, .month, .day], from: today)
        let base = cal.date(from: now) ?? today
        
        let s = hint.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Qx YYYY or Qx next year
        if let m = s.firstMatch(of: #"q([1-4])\s*[-/ ]?\s*(\d{4}|next year)"#) {
            let q = Int(m[1]) ?? 1
            let year: Int = {
                if m[2] == "next year" {
                    return (cal.component(.year, from: base) + 1)
                } else {
                    return Int(m[2]) ?? cal.component(.year, from: base)
                }
            }()
            
            let startMonth: Int = [1:1, 2:4, 3:7, 4:10][q] ?? 1
            let start = cal.date(from: DateComponents(year: year, month: startMonth, day: 1)) ?? base
            // Approx quarter = ~90 days
            let end = cal.date(byAdding: .day, value: 89, to: start) ?? start
            
            let adj = adjustedFutureRange(start: start, end: end, today: base, cal: cal)
            return TimelineWindow(start: adj.start.isoDate, end: adj.end.isoDate, rationale: nil)
        }
        
        // Relative "N weeks/months/days"
        if let m = s.firstMatch(of: #"(\d+)\s*(weeks|week|months|month|days|day)"#) {
            let n = Int(m[1]) ?? 8
            let unit = m[2]
            let deltaDays: Int = {
                switch unit {
                case "months", "month": return n * 30
                case "weeks", "week":   return n * 7
                default:                return n
                }
            }()
            
            let start = cal.date(byAdding: .day, value: 14, to: base) ?? base.addingTimeInterval(14*86400)
            let end = cal.date(byAdding: .day, value: deltaDays, to: base) ?? base
            let adj = adjustedFutureRange(start: start, end: end, today: base, cal: cal)
            return TimelineWindow(start: adj.start.isoDate, end: adj.end.isoDate, rationale: nil)
        }
        
        // Default: 2–8 weeks from now
        let start = cal.date(byAdding: .day, value: 14, to: base) ?? base.addingTimeInterval(14*86400)
        let end = cal.date(byAdding: .day, value: 60, to: base) ?? base.addingTimeInterval(60*86400)
        let adj = adjustedFutureRange(start: start, end: end, today: base, cal: cal)
        return TimelineWindow(start: adj.start.isoDate, end: adj.end.isoDate, rationale: nil)
    }
    
    private static func adjustedFutureRange(start: Date, end: Date, today: Date, cal: Calendar) -> (start: Date, end: Date) {
        guard end < today else { return (start, end) }
        // Roll forward so end is 2 weeks in the future
        let shift = cal.dateComponents([.day], from: end, to: today).day ?? 0
        let add = shift + 14
        let s = cal.date(byAdding: .day, value: add, to: start) ?? start
        let e = cal.date(byAdding: .day, value: add, to: end) ?? end
        return (s, e)
    }
    
    // MARK: - Generic Acceptance Criteria Composer
    
    /// Compose generic acceptance criteria from must-have requirements
    public static func composeGenericAC(mustHaves: [String]) -> [AcceptanceClause] {
        var out: [AcceptanceClause] = []
        for (idx, req) in mustHaves.enumerated() {
            let title = "Requirement \(idx + 1): \(String(req.prefix(80)))"
            let ac = AcceptanceClause(
                title: title,
                given: "the system is configured per the PRD and all dependencies are available",
                when: "the user or CI triggers the behavior related to '\(req)'",
                then: [
                    "the system completes '\(req)' without errors",
                    "all required side-effects are observable (logs, events, or artifacts)"
                ],
                performance: "p95 end-to-end time ≤ target (see Non-Functional Requirements)",
                observability: [
                    "success_rate over 7d ≥ specified threshold",
                    "alert if ≥ 3 consecutive failures OR p95 exceeds target by 20%"
                ]
            )
            out.append(ac)
        }
        return out
    }
    
    // MARK: - Risk Normalization
    
    /// Normalize risks with intelligent defaults and auto-mitigation
    public static func normalizeRisks(_ raw: [RiskItem]) -> [RiskItem] {
        var items = raw
        
        // Add default risks if empty
        if items.isEmpty {
            items = [
                RiskItem(
                    name: "Low adoption",
                    description: "Users do not switch to new process",
                    probability: "Medium",
                    impact: "High",
                    mitigation: "Pilot, feedback loop, clear comms",
                    owner: nil,
                    earlyWarning: "Low activation in first 2 weeks"
                ),
                RiskItem(
                    name: "Integration gaps",
                    description: "Dependencies or APIs not compatible",
                    probability: "Medium",
                    impact: "High",
                    mitigation: "Spike early, graceful fallbacks",
                    owner: nil,
                    earlyWarning: "Build/test failures on integration jobs"
                ),
                RiskItem(
                    name: "Timeline slip",
                    description: "Unplanned refactors push dates",
                    probability: "Medium",
                    impact: "Medium",
                    mitigation: "Timebox scope, MVP gate",
                    owner: nil,
                    earlyWarning: ">10% slip on critical path tasks"
                )
            ]
        } else {
            // Clean up existing risks
            items = items.map { r in
                var r = r
                if r.mitigation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    r.mitigation = "Add mitigation plan"
                }
                if r.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    r.description = "No description"
                }
                if r.probability.isEmpty { r.probability = "Medium" }
                if r.impact.isEmpty { r.impact = "Medium" }
                return r
            }
        }
        
        // Auto-fill generic mitigations if they look empty
        items = items.map { r in
            var r = r
            if r.mitigation == "Add mitigation plan" {
                switch r.name.lowercased() {
                case _ where r.name.lowercased().contains("delay"):
                    r.mitigation = "Timebox scope; add capacity buffer; freeze non-critical changes"
                case _ where r.name.lowercased().contains("compatibility"):
                    r.mitigation = "Run early compatibility spike; define fallback versions; isolate incompatible modules"
                default:
                    r.mitigation = "Define early spike + fallback; monitor KPIs weekly"
                }
            }
            return r
        }
        
        return items
    }
    
    // MARK: - Observability Auto-Generation
    
    /// Generate observability rules from metrics
    public static func autoObservability(from metrics: [Metric]) -> [String] {
        var out: [String] = []
        for m in metrics {
            out.append("Track '\(m.name)' (\(m.unit)) and alert if deviates > 20% from target '\(m.target)' before \(m.timeframe).")
        }
        if out.isEmpty {
            out = [
                "Track success_rate over 7d; alert if < 99%.",
                "Track p95 latency; alert if above target for 60 minutes."
            ]
        }
        return out
    }
    
    // MARK: - Feasibility Estimation
    
    public struct Feasibility: Codable {
        public let feasible: Bool
        public let estimatedPersonDays: Int
        public let capacityPersonDays: Int
        public let assumptions: [String: String]
    }
    
    /// Estimate feasibility based on requirements and team capacity
    public static func estimateFeasibility(
        mustHaves: [String],
        dependencies: [String],
        teamSize: Int,
        weeks: Int
    ) -> Feasibility {
        let perMust = 3
        let perDep = 1
        var workDays = mustHaves.count * perMust + dependencies.count * perDep
        workDays = Int(Double(workDays) * 1.2) // +20% buffer
        let capacity = max(teamSize, 1) * max(weeks, 1) * 5
        
        return Feasibility(
            feasible: capacity >= workDays,
            estimatedPersonDays: workDays,
            capacityPersonDays: capacity,
            assumptions: ["perMust": "\(perMust)", "perDep": "\(perDep)", "buffer": "20%"]
        )
    }
    
    // MARK: - Validators
    
    /// Validate timeline has sensible dates
    public static func validateTimeline(_ tl: TimelineWindow) -> Bool {
        guard let s = tl.start.asISODate, let e = tl.end.asISODate else { return false }
        let today = Date()
        return s <= e && e >= today
    }
    
    /// Validate metrics have required fields and numeric targets
    public static func validateMetrics(_ metrics: [Metric]) -> Bool {
        guard !metrics.isEmpty else { return false }
        for m in metrics {
            guard !m.name.isEmpty, !m.unit.isEmpty, !m.baseline.isEmpty,
                  !m.target.isEmpty, !m.timeframe.isEmpty else {
                return false
            }
            // Target must contain a digit
            if m.target.rangeOfCharacter(from: .decimalDigits) == nil { return false }
        }
        return true
    }
    
    // MARK: - N-Best Reranking
    
    /// Score a PRD candidate based on completeness and specificity
    public static func scoreCandidate(_ prd: GenericPRD) -> Int {
        let encoder = JSONEncoder()
        let txt = (try? String(data: encoder.encode(prd), encoding: .utf8)) ?? ""
        let digits = txt.filter(\.isNumber).count
        let banned = ["improve", "user-friendly", "modern", "some", "many", "various", "optimize"]
            .reduce(0) { $0 + (txt.lowercased().contains($1) ? 1 : 0) }
        
        var coverage = 0
        if !prd.functionalRequirements.isEmpty { coverage += 1 }
        if !prd.nonFunctionalRequirements.isEmpty { coverage += 1 }
        if !prd.acceptanceCriteria.isEmpty { coverage += 1 }
        if !prd.successMetrics.isEmpty { coverage += 1 }
        if !prd.timeline.start.isEmpty && !prd.timeline.end.isEmpty { coverage += 1 }
        if !prd.risks.isEmpty { coverage += 1 }
        
        return coverage * 10 + digits - banned * 3
    }
    
    /// Pick the best PRD from candidates
    public static func pickBest(_ candidates: [GenericPRD]) -> GenericPRD? {
        guard !candidates.isEmpty else { return nil }
        return candidates.max(by: { scoreCandidate($0) < scoreCandidate($1) })
    }
}

// MARK: - String Extensions

extension String {
    var isoDate: String { self }
    
    var asISODate: Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f.date(from: self)
    }
    
    func matches(of pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.dotMatchesLineSeparators, .caseInsensitive]
        ) else { return [] }
        
        let nsrange = NSRange(startIndex..., in: self)
        let matches = regex.matches(in: self, range: nsrange)
        
        return matches.compactMap { match in
            guard match.numberOfRanges >= 1 else { return nil }
            let r = match.range(at: 0)
            guard let rr = Range(r, in: self) else { return nil }
            return String(self[rr])
        }
    }
    
    func firstMatch(of pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else { return nil }
        
        let nsrange = NSRange(startIndex..., in: self)
        guard let m = regex.firstMatch(in: self, range: nsrange) else { return nil }
        
        var caps: [String] = []
        for i in 0..<m.numberOfRanges {
            let r = m.range(at: i)
            if let rr = Range(r, in: self) {
                caps.append(String(self[rr]))
            } else {
                caps.append("")
            }
        }
        return caps
    }
}

// MARK: - Date Extensions

extension Date {
    var isoDate: String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f.string(from: self)
    }
}