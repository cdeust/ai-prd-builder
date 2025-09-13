import Foundation

// MARK: - PRD Generator with Structured Approach

public class StructuredPRDGenerator {
    
    // MARK: - Multi-Stage Generation Pipeline
    
    public enum GenerationStage {
        case research
        case planning 
        case drafting
        case critique
        case refinement
        case validation
    }
    
    // MARK: - Stage 1: Deep Research & Analysis
    
    public static func createResearchPrompt(
        feature: String,
        context: String,
        requirements: [String]
    ) -> String {
        let contextReference = DomainKnowledge.generateContextReference(
            feature: feature,
            context: context,
            requirements: requirements
        )
        
        return """
        # PRD Research & Analysis Phase
        
        You are a senior product strategist conducting comprehensive research.
        
        Feature: \(feature)
        Context: \(context)
        Requirements: \(requirements.joined(separator: "\n- "))
        
        \(contextReference)
        
        Conduct deep analysis and output JSON with these insights:
        {
          "problem_analysis": {
            "root_cause": "specific root cause with evidence",
            "current_cost": "quantified cost (time/money)",
            "affected_users": "number and profile of affected users",
            "frequency": "how often this problem occurs",
            "workarounds": ["current workaround 1", "workaround 2"]
          },
          "market_research": {
            "competitors": [{"name": "X", "solution": "their approach", "weakness": "gap"}],
            "best_practices": ["industry standard 1", "standard 2"],
            "innovation_opportunities": ["unique approach 1", "approach 2"]
          },
          "technical_feasibility": {
            "architecture_pattern": "recommended pattern and why",
            "technology_stack": ["tech 1", "tech 2"],
            "complexity_score": 1-10,
            "main_challenges": ["challenge 1", "challenge 2"],
            "performance_targets": {"latency": "Xms", "throughput": "Y/sec"}
          },
          "business_impact": {
            "revenue_impact": "$X per month/year",
            "cost_savings": "$Y per month/year",
            "efficiency_gain": "Z% improvement",
            "strategic_value": "high/medium/low with justification",
            "payback_period": "X months"
          },
          "user_insights": {
            "primary_persona": {"title": "X", "needs": ["need 1"], "pain_level": 1-10},
            "use_cases": [{"scenario": "X", "frequency": "daily/weekly", "value": "high/medium"}],
            "success_criteria": ["user can do X in Y seconds", "reduce errors by Z%"]
          }
        }
        
        Be specific, quantified, and evidence-based. No vague statements.
        """
    }
    
    // MARK: - Stage 2: Strategic Planning
    
    public static func createPlannerPrompt(
        feature: String,
        context: String,
        requirements: [String],
        research: String? = nil
    ) -> String {
        let researchContext = research != nil ? "\nBased on research:\n\(research!)\n" : ""
        
        return """
        # PRD Strategic Planning Phase
        
        You are a technical architect planning implementation strategy.
        
        Feature: \(feature)
        Context: \(context)
        Requirements: \(requirements.joined(separator: "; "))
        \(researchContext)
        
        Create a comprehensive plan with specific, measurable items:
        {
          "discovery_facts": [
            "Problem: X costs $Y/month affecting Z users",
            "Current solution takes A minutes, target is B seconds"
          ],
          "scope_items": [
            "P0: Core feature X with acceptance criteria Y",
            "P1: Enhancement A with metric B"
          ],
          "acceptance_tests": [
            "GIVEN user in state X WHEN action Y THEN result Z in <2s",
            "API endpoint /X returns Y in <100ms p95"
          ],
          "risks": [
            "Risk: X (probability: 60%, impact: high, mitigation: Y)",
            "Dependency on Z team (mitigation: early alignment, fallback: W)"
          ],
          "metrics": [
            "Reduce process time from 10min to 30sec by Q2",
            "Increase success rate from 75% to 99.9% within 30 days"
          ],
          "timeline_phases": [
            "Phase 1 (2 weeks): Foundation - API design, data model, CI/CD",
            "Phase 2 (3 weeks): Core features - X, Y, Z with tests"
          ],
          "technical_decisions": [
            "Use pattern X because Y (alternative: Z, tradeoff: W)",
            "Database: PostgreSQL for ACID, considered MongoDB but need transactions"
          ]
        }
        
        Every item must be specific, quantified, and actionable.
        """
    }
    
    // MARK: - Stage 3: Detailed Drafting
    
    public static func createDrafterPrompt(
        plan: String,
        section: String,
        context: String? = nil
    ) -> String {
        let contextInfo = context != nil ? "\nContext: \(context!)\n" : ""
        
        return """
        # PRD Section Drafting: \(section)
        
        You are a technical writer creating detailed specifications.
        
        Planning Data:
        \(plan)
        \(contextInfo)
        
        Generate comprehensive \(section) section with:
        \(getSectionRequirements(section))
        
        Output valid JSON matching this exact schema:
        \(getSchemaForSection(section))
        
        Requirements:
        - Use specific numbers (e.g., "99.9%" not "high")
        - Include units (ms, %, requests/sec)
        - Dates in ISO format (YYYY-MM-DD)
        - Technical terms precise and accurate
        - Every field must have meaningful content
        - Include rationale for decisions
        
        Make it immediately actionable for developers.
        """
    }
    
    private static func getSectionRequirements(_ section: String) -> String {
        switch section {
        case "acceptance_criteria":
            return """
            - Clear GIVEN-WHEN-THEN format
            - Specific performance targets (p95, throughput)
            - Observable outcomes
            - Edge cases covered
            - Error conditions defined
            """
        case "technical_specification":
            return """
            - API endpoints with request/response schemas
            - Data model with relationships
            - Architecture decisions with rationale
            - Security requirements
            - Integration points
            """
        case "metrics":
            return """
            - Baseline measurements
            - Specific targets with units
            - Measurement methodology
            - Alert thresholds
            - Business impact correlation
            """
        case "implementation":
            return """
            - Phased delivery plan
            - Dependencies and prerequisites  
            - Resource requirements
            - Milestone criteria
            - Rollback procedures
            """
        default:
            return "Complete, specific, and actionable information"
        }
    }
    
    private static func getSchemaForSection(_ section: String) -> String {
        switch section {
        case "acceptance_criteria":
            return """
            [{
              "id": "AC-001",
              "feature": "specific feature name",
              "title": "descriptive test title",
              "given": "initial state/context",
              "when": "action performed",
              "then": [
                "expected outcome 1",
                "expected outcome 2",
                "performance: completes in <Xms"
              ],
              "edge_cases": ["edge case 1", "edge case 2"],
              "error_handling": "what happens on failure",
              "nonFunctional": {
                "p95DurationMs": 100,
                "p99DurationMs": 200,
                "successRate": "99.9%",
                "throughput": "1000 req/s"
              }
            }]
            """
        case "technical_specification":
            return """
            {
              "architecture": {
                "pattern": "microservices/monolith/serverless",
                "components": [
                  {"name": "X", "responsibility": "Y", "technology": "Z"}
                ],
                "data_flow": "description of data flow"
              },
              "api": [
                {
                  "method": "POST",
                  "path": "/api/v1/resource",
                  "description": "what it does",
                  "auth": "Bearer token/API key",
                  "request": {"field1": "type", "field2": "type"},
                  "response": {"status": 200, "body": {"result": "type"}},
                  "errors": [{"status": 400, "code": "INVALID_X", "message": "X is invalid"}]
                }
              ],
              "database": {
                "entities": [
                  {
                    "name": "users",
                    "fields": [
                      {"name": "id", "type": "uuid", "primary": true},
                      {"name": "email", "type": "varchar(255)", "unique": true}
                    ],
                    "indexes": ["email"],
                    "relationships": [{"to": "orders", "type": "one-to-many"}]
                  }
                ]
              },
              "security": {
                "authentication": "JWT with refresh tokens",
                "authorization": "RBAC with permissions",
                "encryption": "AES-256 at rest, TLS 1.3 in transit",
                "compliance": ["GDPR", "SOC2"]
              }
            }
            """
        case "metrics":
            return """
            {
              "success_metrics": [
                {
                  "name": "User Activation Rate",
                  "description": "% of users who complete first action",
                  "baseline": 45.5,
                  "target": 75.0,
                  "unit": "percent",
                  "measurement": "unique_users_acted / total_new_users",
                  "frequency": "daily",
                  "alert_threshold": "< 60%"
                }
              ],
              "operational_metrics": [
                {
                  "name": "API Latency",
                  "sli": "p95 response time",
                  "slo": "< 100ms",
                  "sla": "99.9% requests < 100ms",
                  "measurement": "histogram_quantile(0.95, http_request_duration_ms)"
                }
              ],
              "business_metrics": [
                {
                  "name": "Revenue Impact",
                  "formula": "(new_conversion_rate - old_conversion_rate) * traffic * avg_order_value",
                  "target": "$50K/month increase",
                  "tracking": "finance dashboard"
                }
              ]
            }
            """
        default:
            return "{}"
        }
    }
    
    // MARK: - Stage 4: Critical Analysis
    
    public static func createCritiquePrompt(_ draft: String) -> String {
        return """
        # PRD Critical Review
        
        You are a senior technical reviewer evaluating this PRD for production readiness.
        
        PRD Draft:
        \(draft)
        
        Evaluate critically and output JSON:
        {
          "scores": {
            "completeness": 0-100,
            "clarity": 0-100,
            "feasibility": 0-100,
            "measurability": 0-100,
            "technical_depth": 0-100
          },
          "gaps": [
            {"section": "X", "issue": "missing Y", "severity": "critical/high/medium"},
            {"section": "Z", "issue": "vague metric W", "severity": "high"}
          ],
          "strengths": [
            "Clear API specifications",
            "Well-defined success metrics"
          ],
          "improvements": [
            {"current": "X", "suggested": "Y", "rationale": "Z"},
            {"current": "vague timeline", "suggested": "Phase 1: 2 weeks (Jan 15-29)", "rationale": "specificity"}
          ],
          "risks_not_addressed": [
            "No rollback plan defined",
            "Missing performance testing strategy"
          ],
          "overall_assessment": {
            "ready_for_development": true/false,
            "blocking_issues": ["issue 1", "issue 2"],
            "recommendation": "approve/revise/reject"
          }
        }
        
        Be thorough and critical. This PRD will be used for production development.
        """
    }
    
    // MARK: - Stage 5: Iterative Refinement
    
    public static func createRefinementPrompt(_ draft: String, _ critique: String) -> String {
        return """
        # PRD Refinement
        
        You are refining this PRD based on critical feedback.
        
        Current PRD:
        \(draft)
        
        Critical Feedback:
        \(critique)
        
        Generate an improved PRD that:
        1. Addresses ALL identified gaps
        2. Incorporates ALL suggested improvements
        3. Maintains consistency across sections
        4. Adds missing technical details
        5. Clarifies vague statements with specifics
        6. Includes comprehensive risk mitigation
        7. Provides clear rollback procedures
        8. Defines monitoring and alerting
        
        Output the complete refined PRD in the same JSON structure.
        Every field must be specific, measurable, and actionable.
        """
    }
    
    // MARK: - Enhanced Scoring & Validation
    
    public static func scoreOutput(_ output: String, feature: String, context: String, requirements: [String]) -> Double {
        var score = 0.0
        
        // Completeness: check for required keys
        let requiredKeys = ["given", "when", "then", "title"]
        for key in requiredKeys {
            if output.contains("\"\(key)\"") {
                score += 10
            }
        }
        
        // Specificity: count numbers and dates
        let digitCount = output.filter { $0.isNumber }.count
        score += Double(digitCount) * 2
        
        // Context relevance: dynamically extracted keywords
        let contextKeywords = DomainKnowledge.extractKeywords(
            feature: feature,
            context: context,
            requirements: requirements
        )
        for keyword in contextKeywords {
            if output.lowercased().contains(keyword) {
                score += 5
            }
        }
        
        // Penalize vague words
        let vagueWords = ["improve", "better", "enhance", "optimize"]
        for word in vagueWords {
            if output.lowercased().contains(word) {
                score -= 3
            }
        }
        
        // Reward specific metrics
        if output.contains("%") { score += 5 }
        if output.contains("ms") || output.contains("sec") { score += 5 }
        if output.contains("macos-14") || output.contains("macos-13") { score += 10 }
        
        return score
    }
    
    /// Patch vague metrics with concrete values
    public static func patchMetrics(_ input: String) -> String {
        var patched = input
        
        // Replace vague success rates
        patched = patched.replacingOccurrences(
            of: "\"successRate\": \"high\"",
            with: "\"successRate\": \"99.9%\""
        )
        
        // Add missing baselines
        if patched.contains("\"baseline\": null") {
            patched = patched.replacingOccurrences(
                of: "\"baseline\": null",
                with: "\"baseline\": 0"
            )
        }
        
        // Normalize timeline references
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        patched = patched.replacingOccurrences(
            of: "\"next quarter\"",
            with: "\"\(formatter.string(from: today.addingTimeInterval(90*24*3600)))\""
        )
        
        return patched
    }
}
