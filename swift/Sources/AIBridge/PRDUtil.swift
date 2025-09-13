import Foundation

// MARK: - PRD Utilities (Generic, Domain-Agnostic)

public enum PRDUtil {
    
    // MARK: - Multi-Stage PRD Generation Pipeline
    
    public struct GenerationPipeline {
        public let maxIterations: Int = 3
        public let targetScore: Double = 85.0
        
        /// Generate PRD using section-by-section approach for smaller token usage
        public static func generateSectionBasedPRD(
            feature: String,
            context: String,
            requirements: [String],
            projectContext: ProjectContext? = nil,
            generateFunc: (String) async throws -> String
        ) async throws -> (prd: String, score: Double, iterations: Int) {
            
            // Section 1: Executive + Requirements
            let execPrompt = StructuredPRDGenerator.createExecutivePrompt(
                feature: feature,
                context: context,
                requirements: requirements,
                projectContext: projectContext
            )
            let execSection = try await generateFunc(execPrompt)
            
            // Section 2: Acceptance Criteria
            let acceptPrompt = StructuredPRDGenerator.createAcceptancePrompt(
                feature: feature,
                requirements: requirements,
                projectContext: projectContext
            )
            let acceptSection = try await generateFunc(acceptPrompt)
            
            // Section 3: Risks + Rollback
            let risksPrompt = StructuredPRDGenerator.createRisksPrompt(
                feature: feature,
                projectContext: projectContext
            )
            let risksSection = try await generateFunc(risksPrompt)
            
            // Section 4: Tasks + CI
            let tasksPrompt = StructuredPRDGenerator.createTasksPrompt(
                feature: feature,
                projectContext: projectContext
            )
            let tasksSection = try await generateFunc(tasksPrompt)
            
            // Assemble PRD
            let assembledPRD = """
            \(execSection)
            
            \(acceptSection)
            
            ## Timeline:
            Sprint 1: Setup and initial implementation
            Sprint 2: Testing and deployment
            
            \(risksSection)
            
            \(tasksSection)
            """
            
            // Validate the assembled PRD
            let validation = PRDValidator.validate(
                prd: assembledPRD,
                feature: feature,
                context: context,
                projectContext: projectContext
            )
            
            var finalPRD = assembledPRD
            var iterations = 1
            
            // If not production ready, generate refined sections
            if validation.needsRefinement && iterations < 3 {
                // Re-generate only the problematic sections
                var refinedPRD = assembledPRD
                
                // If there are critical gaps, regenerate with more specific prompts
                if !validation.criticalGaps.isEmpty {
                    let issueContext = validation.criticalGaps.joined(separator: "; ")
                    
                    // Generate a refined version focusing on the issues
                    let refinementPrompt = """
                    Fix these specific issues in the PRD:
                    \(issueContext)
                    
                    Keep the same format but add:
                    - Specific numeric thresholds (errors = 0, warnings ≤ 0, coverage ≥ 85%)
                    - Swift 6 concurrency steps (@MainActor, Sendable, strict concurrency)
                    - Actual xcodebuild commands for iOS
                    - Real CI configuration for macOS runners
                    
                    Feature: \(feature)
                    Context: \(context)
                    """
                    
                    if let refined = try? await generateFunc(refinementPrompt) {
                        // Only use the refined content if it's better
                        if !refined.contains("CRITICAL GAPS") && !refined.contains("IMPROVEMENTS:") {
                            finalPRD = refined
                        }
                    }
                }
                iterations += 1
            }
            
            let score = validation.isProductionReady ? 90.0 : 75.0
            
            return (finalPRD, score, iterations)
        }
        
        /// Execute multi-stage PRD generation with refinement
        public static func generateEnhancedPRD(
            feature: String,
            context: String,
            requirements: [String],
            projectContext: ProjectContext? = nil,
            generateFunc: (String) async throws -> String
        ) async throws -> (prd: String, score: Double, iterations: Int) {
            
            var currentPRD = ""
            var currentScore = 0.0
            var iteration = 0
            
            // Stage 1: Research
            let researchPrompt = StructuredPRDGenerator.createResearchPrompt(
                feature: feature,
                context: context,
                requirements: requirements,
                projectContext: projectContext
            )
            let research = try await generateFunc(researchPrompt)
            
            // Stage 2: Planning
            let planPrompt = StructuredPRDGenerator.createPlannerPrompt(
                feature: feature,
                context: context,
                requirements: requirements,
                research: research,
                projectContext: projectContext
            )
            let plan = try await generateFunc(planPrompt)
            
            // Stage 3: Initial Draft
            let draftPrompt = StructuredPRDGenerator.createDrafterPrompt(
                plan: plan,
                section: "complete_prd",
                feature: feature,
                context: context,
                projectContext: projectContext
            )
            currentPRD = try await generateFunc(draftPrompt)
            
            // Stages 4-5: Critique and Refinement Loop
            while iteration < 3 && currentScore < 85.0 {
                let critiquePrompt = StructuredPRDGenerator.createCritiquePrompt(currentPRD)
                let critique = try await generateFunc(critiquePrompt)
                
                // Parse critique score
                currentScore = extractScoreFromCritique(critique)
                
                if currentScore < 85.0 {
                    let refinementPrompt = StructuredPRDGenerator.createRefinementPrompt(
                        currentPRD,
                        critique
                    )
                    currentPRD = try await generateFunc(refinementPrompt)
                }
                
                iteration += 1
            }
            
            return (currentPRD, currentScore, iteration)
        }
        
        private static func extractScoreFromCritique(_ critique: String) -> Double {
            // Extract scores from plain text critique format
            var totalScore = 0.0
            var scoreCount = 0
            
            // Look for patterns like "Completeness (8/10)" or "Clarity (1-10): 7"
            let patterns = [
                #"(\d+)/10"#,     // Matches "8/10"
                #"\((\d+)-10\):\s*(\d+)"#,  // Matches "(1-10): 7"
                #"\b(\d+)\s*(?:out of|/)\s*10\b"# // Matches "7 out of 10" or "7/10"
            ]
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let matches = regex.matches(in: critique, range: NSRange(critique.startIndex..., in: critique))
                    for match in matches {
                        if let range = Range(match.range(at: 1), in: critique),
                           let score = Double(critique[range]) {
                            totalScore += score * 10  // Convert to percentage
                            scoreCount += 1
                        }
                    }
                }
            }
            
            // Also check for "Overall: Ready" or "Overall: Not ready"
            if critique.lowercased().contains("ready for development? yes") ||
               critique.lowercased().contains("overall: ready") {
                return max(85.0, scoreCount > 0 ? totalScore / Double(scoreCount) : 85.0)
            } else if critique.lowercased().contains("ready for development? no") ||
                      critique.lowercased().contains("overall: not ready") {
                return min(70.0, scoreCount > 0 ? totalScore / Double(scoreCount) : 70.0)
            }
            
            return scoreCount > 0 ? totalScore / Double(scoreCount) : 75.0
        }
    }
    
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
    
    // MARK: - Enhanced PRD Scoring
    
    public struct PRDScorer {
        
        /// Comprehensive scoring with multiple dimensions
        public static func scoreEnhanced(_ prdText: String) -> DetailedScore {
            var score = DetailedScore()
            
            // Completeness checks
            score.completeness = calculateCompleteness(prdText)
            
            // Specificity (numbers, dates, metrics)
            score.specificity = calculateSpecificity(prdText)
            
            // Technical depth
            score.technicalDepth = calculateTechnicalDepth(prdText)
            
            // Clarity (absence of vague terms)
            score.clarity = calculateClarity(prdText)
            
            // Actionability
            score.actionability = calculateActionability(prdText)
            
            // Calculate overall
            score.overall = (score.completeness * 0.2 +
                           score.specificity * 0.25 +
                           score.technicalDepth * 0.25 +
                           score.clarity * 0.15 +
                           score.actionability * 0.15)
            
            return score
        }
        
        private static func calculateCompleteness(_ text: String) -> Double {
            let requiredSections = [
                "problem", "solution", "requirements", "acceptance",
                "metrics", "timeline", "risks", "api", "database",
                "security", "monitoring", "deployment"
            ]
            
            let found = requiredSections.filter { text.lowercased().contains($0) }.count
            return Double(found) / Double(requiredSections.count) * 100
        }
        
        private static func calculateSpecificity(_ text: String) -> Double {
            let numbers = text.filter { $0.isNumber }.count
            let percentages = text.matches(of: #"\d+(\.\d+)?%"#).count
            let timeUnits = text.matches(of: #"\d+\s*(ms|sec|min|hour|day|week|month)"#).count
            let dates = text.matches(of: #"\d{4}-\d{2}-\d{2}"#).count
            
            let specificityScore = Double(numbers + percentages * 2 + timeUnits * 2 + dates * 3)
            return min(specificityScore / 2, 100) // Normalize to 0-100
        }
        
        private static func calculateTechnicalDepth(_ text: String) -> Double {
            let technicalTerms = [
                "api", "endpoint", "database", "schema", "authentication",
                "authorization", "encryption", "latency", "throughput",
                "scalability", "microservice", "cache", "queue", "webhook",
                "rest", "graphql", "grpc", "jwt", "oauth", "rbac"
            ]
            
            let found = technicalTerms.filter { text.lowercased().contains($0) }.count
            return Double(found) / Double(technicalTerms.count) * 100
        }
        
        private static func calculateClarity(_ text: String) -> Double {
            let vagueTerms = [
                "improve", "enhance", "optimize", "better", "various",
                "some", "many", "several", "appropriate", "suitable",
                "user-friendly", "modern", "robust", "flexible"
            ]
            
            let vagueCount = vagueTerms.reduce(0) { count, term in
                count + (text.lowercased().contains(term) ? 1 : 0)
            }
            
            return max(100 - Double(vagueCount * 10), 0)
        }
        
        private static func calculateActionability(_ text: String) -> Double {
            let actionIndicators = [
                "must", "shall", "will", "should", "given", "when", "then",
                "endpoint:", "method:", "path:", "request:", "response:",
                "field:", "type:", "create", "implement", "deploy"
            ]
            
            let found = actionIndicators.filter { text.lowercased().contains($0) }.count
            return Double(found) / Double(actionIndicators.count) * 100
        }
        
        public struct DetailedScore {
            public var completeness: Double = 0
            public var specificity: Double = 0
            public var technicalDepth: Double = 0
            public var clarity: Double = 0
            public var actionability: Double = 0
            public var overall: Double = 0
            
            public var summary: String {
                """
                PRD Quality Score: \(String(format: "%.1f", overall))%
                - Completeness: \(String(format: "%.1f", completeness))%
                - Specificity: \(String(format: "%.1f", specificity))%
                - Technical Depth: \(String(format: "%.1f", technicalDepth))%
                - Clarity: \(String(format: "%.1f", clarity))%
                - Actionability: \(String(format: "%.1f", actionability))%
                """
            }
        }
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
    
    // MARK: - PRD Export Formats
    
    public struct PRDExporter {
        
        /// Export PRD to developer-friendly Markdown
        public static func exportToMarkdown(_ prd: GenericPRD) -> String {
            var md = """
            # Product Requirements Document
            
            **Timeline:** \(prd.timeline.start) to \(prd.timeline.end)  
            **Version:** 1.0.0  
            **Status:** Draft
            
            ---
            
            ## 📋 Executive Summary
            
            \(prd.executiveSummary)
            
            ### Problem Statement
            \(prd.problemStatement)
            
            ### Target Users
            \(prd.targetUsers.map { "- \($0)" }.joined(separator: "\n"))
            
            ---
            
            ## 🎯 Functional Requirements
            
            """
            
            for (index, req) in prd.functionalRequirements.enumerated() {
                md += "\n### FR-\(String(format: "%03d", index + 1))\n"
                md += "\(req)\n"
            }
            
            md += "\n---\n\n## ⚡ Non-Functional Requirements\n\n"
            
            for req in prd.nonFunctionalRequirements {
                md += "- \(req)\n"
            }
            
            md += "\n---\n\n## ✅ Acceptance Criteria\n\n"
            
            for (index, ac) in prd.acceptanceCriteria.enumerated() {
                md += "\n### AC-\(String(format: "%03d", index + 1)): \(ac.title)\n"
                md += "- **Given:** \(ac.given)\n"
                md += "- **When:** \(ac.when)\n"
                md += "- **Then:**\n"
                for outcome in ac.then {
                    md += "  - \(outcome)\n"
                }
                if let perf = ac.performance {
                    md += "- **Performance:** \(perf)\n"
                }
            }
            
            md += "\n---\n\n## 📊 Success Metrics\n\n"
            
            for metric in prd.successMetrics {
                md += "- **\(metric.name)**\n"
                md += "  - Baseline: \(metric.baseline) \(metric.unit)\n"
                md += "  - Target: \(metric.target) \(metric.unit)\n"
                md += "  - Timeline: \(metric.timeframe)\n"
            }
            
            md += "\n---\n\n## ⚠️ Risks & Mitigation\n\n"
            
            for risk in prd.risks {
                md += "\n### \(risk.name)\n"
                md += "- **Description:** \(risk.description)\n"
                md += "- **Probability:** \(risk.probability)\n"
                md += "- **Impact:** \(risk.impact)\n"
                md += "- **Mitigation:** \(risk.mitigation)\n"
                if let warning = risk.earlyWarning {
                    md += "- **Early Warning:** \(warning)\n"
                }
            }
            
            return md
        }
        
        /// Export PRD to JIRA-compatible format
        public static func exportToJIRA(_ prd: GenericPRD) -> [String: Any] {
            return [
                "fields": [
                    "project": ["key": "PRD"],
                    "summary": prd.executiveSummary.prefix(100).description,
                    "description": exportToMarkdown(prd),
                    "issuetype": ["name": "Epic"],
                    "priority": ["name": "Medium"],
                    "labels": prd.functionalRequirements,
                    "components": [],
                    "customfield_storypoints": prd.functionalRequirements.count * 3,
                    "customfield_acceptance_criteria": prd.acceptanceCriteria.map { ac in
                        "GIVEN \(ac.given) WHEN \(ac.when) THEN \(ac.then.joined(separator: " AND "))"
                    }.joined(separator: "\n"),
                    "customfield_success_metrics": prd.successMetrics.map { metric in
                        "\(metric.name): \(metric.baseline) → \(metric.target) \(metric.unit)"
                    }.joined(separator: "\n")
                ]
            ]
        }
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
