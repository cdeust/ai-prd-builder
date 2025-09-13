public struct ProjectContextDiscovery {
    
    public static func createDiscoveryPrompt(
        feature: String,
        context: String
    ) -> String {
        let scope = StructuredPRDGenerator.ProjectScope.detect(from: feature, context: context)
        
        let scopeSpecific: String
        switch scope {
        case .migration:
            scopeSpecific = """
            MIGRATION SPECIFIC:
            - Current version/compiler?
            - Target version/compiler?
            - Breaking changes already identified?
            - Existing rollback mechanism?
            """
        case .optimization:
            scopeSpecific = """
            OPTIMIZATION SPECIFIC:
            - Current performance metrics (latency, memory, CPU)?
            - Target improvements needed?
            - Performance monitoring tools?
            - Load testing setup?
            """
        case .bugfix:
            scopeSpecific = """
            BUGFIX SPECIFIC:
            - Bug tracking ID/ticket?
            - Reproduction rate?
            - Affected users/systems?
            - Severity/priority?
            """
        default:
            scopeSpecific = ""
        }
        
        return """
        # Project Context Needed for \(String(describing: scope))
        
        To generate an actionable PRD for: "\(feature)"
        
        Please provide (leave blank if unknown):
        
        TEAM & PROCESS:
        1. Team size?
        2. Sprint duration?
        3. Definition of done?
        
        TECHNICAL SETUP:
        4. CI/CD pipeline (GitHub Actions/Jenkins/etc)?
        5. Test framework (XCTest/Quick/etc)?
        6. Deployment method (TestFlight/Docker/etc)?
        7. Monitoring/alerting (Datadog/Sentry/etc)?
        
        CURRENT STATE:
        8. Relevant tech debt?
        9. Hard constraints (deadline/budget)?
        10. Existing rollback mechanism?
        
        \(scopeSpecific)
        
        The more context provided, the more actionable the PRD.
        Missing info will use placeholders like [TEAM_SIZE] or [CI_PIPELINE].
        """
    }
    
    public static func parseContextFromInput(_ input: String) -> ProjectContext {
        // This would parse user input to extract context
        // For now, return empty context
        return ProjectContext()
    }
}
