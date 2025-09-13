import Foundation
import AIBridge

public enum PRDWorkflow {
    
    private static func gatherProjectContext(feature: String, context: String) -> ProjectContext {
        let scope = StructuredPRDGenerator.ProjectScope.detect(from: feature, context: context)
        
        print("\n🔍 Detected project type: \(scope)")
        print("To generate an actionable PRD, I need some project details:")
        print("(Press Enter to skip if unknown - will use placeholders)\n")
        
        // Team & Process
        print("Team size (e.g., '3', '5'): ", terminator: "")
        let teamSizeStr = readLine() ?? ""
        let teamSize = Int(teamSizeStr)
        
        print("Sprint duration (e.g., '2 weeks', '1 week'): ", terminator: "")
        let sprintDuration = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Technical Setup
        print("CI/CD pipeline (e.g., 'GitHub Actions', 'Jenkins', 'Xcode Cloud'): ", terminator: "")
        let ciPipeline = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("Test framework (e.g., 'XCTest', 'Quick', 'Nimble'): ", terminator: "")
        let testFramework = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("Deployment method (e.g., 'TestFlight', 'App Store Connect', 'Docker'): ", terminator: "")
        let deploymentMethod = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Scope-specific questions
        var currentVersion: String? = nil
        var targetVersion: String? = nil
        var performanceBaselines: [String: String] = [:]
        
        if scope == .migration {
            print("\n📦 Migration specific:")
            print("Current version (e.g., 'Swift 5.1', 'iOS 16'): ", terminator: "")
            currentVersion = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("Target version (e.g., 'Swift 6.2', 'iOS 18'): ", terminator: "")
            targetVersion = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if scope == .optimization {
            print("\n📊 Performance baselines:")
            print("Current latency (e.g., '200ms p95'): ", terminator: "")
            if let latency = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !latency.isEmpty {
                performanceBaselines["latency"] = latency
            }
            
            print("Current memory usage (e.g., '150MB'): ", terminator: "")
            if let memory = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !memory.isEmpty {
                performanceBaselines["memory"] = memory
            }
        }
        
        // Rollback mechanism
        print("\nRollback mechanism (e.g., 'git revert', 'feature flags', 'blue-green'): ", terminator: "")
        let rollbackMechanism = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Tech debt and constraints
        print("\nAny relevant tech debt? (comma separated): ", terminator: "")
        let techDebtStr = readLine() ?? ""
        let techDebt = techDebtStr.isEmpty ? [] : techDebtStr.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        
        print("Hard constraints (deadline, budget)? (comma separated): ", terminator: "")
        let constraintsStr = readLine() ?? ""
        let constraints = constraintsStr.isEmpty ? [] : constraintsStr.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        
        return ProjectContext(
            teamSize: teamSize,
            sprintDuration: sprintDuration?.isEmpty == false ? sprintDuration : nil,
            ciPipeline: ciPipeline?.isEmpty == false ? ciPipeline : nil,
            testFramework: testFramework?.isEmpty == false ? testFramework : nil,
            deploymentMethod: deploymentMethod?.isEmpty == false ? deploymentMethod : nil,
            currentVersion: currentVersion?.isEmpty == false ? currentVersion : nil,
            targetVersion: targetVersion?.isEmpty == false ? targetVersion : nil,
            performanceBaselines: performanceBaselines,
            techDebt: techDebt,
            constraints: constraints,
            monitoringTools: [],
            rollbackMechanism: rollbackMechanism?.isEmpty == false ? rollbackMechanism : nil
        )
    }
    
    /// Runs a detailed interactive PRD flow. For now, this stub just prompts the user
    /// for a few inputs and calls Orchestrator.generatePRD, then prints the result.
    public static func runDetailedInteractivePRD(orchestrator: Orchestrator) async {
        print("🧩 PRD Workflow - Interactive")
        
        func readNonEmpty(prompt: String) -> String {
            while true {
                print(prompt, terminator: "")
                if let line = readLine(), !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return line
                }
                print("Please enter a value.")
            }
        }
        
        let feature = readNonEmpty(prompt: "Feature: ")
        print("Context (optional): ", terminator: "")
        let context = readLine() ?? ""
        print("Priority [critical/high/medium/low] (default: medium): ", terminator: "")
        let priorityRaw = (readLine() ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let priority = priorityRaw.isEmpty ? "medium" : priorityRaw
        
        var requirements: [String] = []
        print("Enter requirements (one per line). Leave empty line to finish.")
        while true {
            print("- ", terminator: "")
            let line = readLine() ?? ""
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { break }
            requirements.append(line)
        }
        
        // Phase 1: Start with minimal context
        print("\n📋 Analyzing requirements...")
        var enrichedContext = context
        var projectContext = ProjectContext(
            teamSize: nil,
            sprintDuration: nil,
            ciPipeline: nil,
            testFramework: nil,
            deploymentMethod: nil,
            currentVersion: nil,
            targetVersion: nil,
            performanceBaselines: [:],
            techDebt: [],
            constraints: [],
            monitoringTools: [],
            rollbackMechanism: nil
        )
        
        do {
            var currentPRD = ""
            var iteration = 0
            let maxIterations = 5
            
            // Generate initial PRD with minimal info
            var (content, provider, _) = try await orchestrator.generatePRD(
                feature: feature,
                context: enrichedContext,
                priority: priority,
                requirements: requirements,
                projectContext: projectContext,
                useAppleIntelligence: true,
                useEnhancedGeneration: true
            )
            currentPRD = content
            
            // Phase 2: Validation and refinement loop
            while iteration < maxIterations {
                iteration += 1
                
                // Validate the generated PRD
                let validation = PRDValidator.validate(
                    prd: currentPRD,
                    feature: feature,
                    context: enrichedContext,
                    projectContext: projectContext
                )
                
                if validation.isProductionReady {
                    print("\n✅ PRD is production-ready after \(iteration) iteration(s)")
                    break
                }
                
                // Determine what's missing and ask for it
                var questionsAsked = false
                
                // First iteration: Focus on critical missing info
                if iteration == 1 && (!validation.criticalGaps.isEmpty || !validation.clarifyingQuestions.isEmpty) {
                    print("\n❓ I need some information to create a production-ready PRD:")
                    
                    // Analyze gaps to generate smart questions
                    var questions: [String] = []
                    
                    for gap in validation.criticalGaps {
                        if gap.contains("baseline") && questions.count < 3 {
                            questions.append("What are your current metrics? (warnings count, coverage %, build time)")
                        } else if gap.contains("CI") && gap.contains("iOS") && questions.count < 3 {
                            questions.append("Which Xcode version and macOS runner do you use in CI?")
                        } else if gap.contains("concurrency") && questions.count < 3 {
                            questions.append("Will you enable strict concurrency checking? Any @MainActor requirements?")
                        } else if gap.contains("rollback") && gap.contains("trigger") && questions.count < 3 {
                            questions.append("What should trigger a rollback? (e.g., 'build fails', 'coverage < 85%')")
                        }
                    }
                    
                    // Add any validator questions not covered
                    for question in validation.clarifyingQuestions {
                        if questions.count < 4 && !questions.contains(where: { $0.lowercased().contains(question.lowercased().prefix(20)) }) {
                            questions.append(question)
                        }
                    }
                    
                    // Ask the questions
                    for (idx, question) in questions.enumerated() {
                        print("\n\(idx + 1). \(question)")
                        print("   > ", terminator: "")
                        if let answer = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), 
                           !answer.isEmpty && answer.lowercased() != "tbd" {
                            enrichedContext += " \(question.replacingOccurrences(of: "?", with: ":")): \(answer)."
                            questionsAsked = true
                            
                            // Parse answer to update projectContext
                            if question.contains("Xcode") {
                                let pipeline = answer.contains("GitHub") ? "GitHub Actions" : 
                                              answer.contains("Cloud") ? "Xcode Cloud" : answer
                                projectContext = ProjectContext(
                                    teamSize: projectContext.teamSize,
                                    sprintDuration: projectContext.sprintDuration,
                                    ciPipeline: pipeline,
                                    testFramework: projectContext.testFramework,
                                    deploymentMethod: projectContext.deploymentMethod,
                                    currentVersion: projectContext.currentVersion,
                                    targetVersion: projectContext.targetVersion,
                                    performanceBaselines: projectContext.performanceBaselines,
                                    techDebt: projectContext.techDebt,
                                    constraints: projectContext.constraints,
                                    monitoringTools: projectContext.monitoringTools,
                                    rollbackMechanism: projectContext.rollbackMechanism
                                )
                            }
                            if question.contains("coverage") {
                                if let range = answer.range(of: #"\d+"#, options: .regularExpression) {
                                    let coverage = String(answer[range])
                                    var baselines = projectContext.performanceBaselines
                                    baselines["coverage"] = "\(coverage)%"
                                    projectContext = ProjectContext(
                                        teamSize: projectContext.teamSize,
                                        sprintDuration: projectContext.sprintDuration,
                                        ciPipeline: projectContext.ciPipeline,
                                        testFramework: projectContext.testFramework,
                                        deploymentMethod: projectContext.deploymentMethod,
                                        currentVersion: projectContext.currentVersion,
                                        targetVersion: projectContext.targetVersion,
                                        performanceBaselines: baselines,
                                        techDebt: projectContext.techDebt,
                                        constraints: projectContext.constraints,
                                        monitoringTools: projectContext.monitoringTools,
                                        rollbackMechanism: projectContext.rollbackMechanism
                                    )
                                }
                            }
                            if question.contains("warning") {
                                if let range = answer.range(of: #"\d+"#, options: .regularExpression) {
                                    let warnings = String(answer[range])
                                    var baselines = projectContext.performanceBaselines
                                    baselines["warnings"] = warnings
                                    projectContext = ProjectContext(
                                        teamSize: projectContext.teamSize,
                                        sprintDuration: projectContext.sprintDuration,
                                        ciPipeline: projectContext.ciPipeline,
                                        testFramework: projectContext.testFramework,
                                        deploymentMethod: projectContext.deploymentMethod,
                                        currentVersion: projectContext.currentVersion,
                                        targetVersion: projectContext.targetVersion,
                                        performanceBaselines: baselines,
                                        techDebt: projectContext.techDebt,
                                        constraints: projectContext.constraints,
                                        monitoringTools: projectContext.monitoringTools,
                                        rollbackMechanism: projectContext.rollbackMechanism
                                    )
                                }
                            }
                        }
                    }
                }
                
                // Show issues only if we didn't ask questions
                if !questionsAsked && iteration > 1 {
                    print("\n⚠️ Iteration \(iteration) - Refining based on:")
                    for issue in validation.specificIssues.prefix(2) {
                        print("  • \(issue)")
                    }
                }
                
                // Regenerate with enriched context
                print("\n🔄 Generating improved PRD...")
                let (refined, _, _) = try await orchestrator.generatePRD(
                    feature: feature,
                    context: enrichedContext,
                    priority: priority,
                    requirements: requirements,
                    projectContext: projectContext,
                    useAppleIntelligence: true,
                    useEnhancedGeneration: true
                )
                currentPRD = refined
            }
            
            // Final validation
            let finalValidation = PRDValidator.validate(
                prd: currentPRD,
                feature: feature,
                context: enrichedContext,
                projectContext: projectContext
            )
            
            // Display final status
            if !finalValidation.isProductionReady {
                print("\n⚠️ After \(maxIterations) iterations, some issues remain:")
                if !finalValidation.criticalGaps.isEmpty {
                    for gap in finalValidation.criticalGaps.prefix(3) {
                        print("  • \(gap)")
                    }
                }
                print("\n💡 Manual refinement may be needed.")
            }
            
            print("\n✅ PRD Generated using \(provider.rawValue)")
            print("\n" + String(repeating: "=", count: 60))
            print(currentPRD)
            print(String(repeating: "=", count: 60))
        } catch {
            CommandLineInterface.displayError("Failed to generate PRD: \(error)")
        }
    }
}
