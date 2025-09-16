import Foundation
import AIBridge

/// Executes the different phases of PRD generation
public struct PRDPhaseExecutor {

    private let orchestrator: Orchestrator

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
    }

    // MARK: - Phase 1: Initial Overview

    public func executePhase1(input: String) async throws -> String {
        print(OrchestratorConstants.PRD.phase1)

        let prompt = String(format: PRDConstants.Phase1.template, input)
        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: PRDConstants.DefaultValues.phase1ThinkingMode
        )

        return response
    }

    // MARK: - Phase 2: Feature Enrichment

    public func enrichFeature(_ featureName: String) async throws -> String {
        let prompt = String(format: PRDConstants.Phase2.template, featureName)
        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: PRDConstants.DefaultValues.phase2ThinkingMode
        )

        return response
    }

    // MARK: - Phase 3: API Specifications

    public func executePhase3API(context: String, useAdvancedGeneration: Bool = false) async throws -> String {
        // Use the OpenAPI validator for iterative generation and validation
        let validator = PRDOpenAPIValidator(orchestrator: orchestrator)

        if useAdvancedGeneration {
            // 2025 best practice: Use MCTS with decision trees and formal verification
            print("🎯 Using advanced MCTS-based generation with formal verification...")
            return try await validator.generateWithMCTS(context: context, maxIterations: 30)
        } else {
            // Traditional iterative approach with self-consistency option
            return try await validator.generateValidOpenAPISpec(context: context)
        }
    }

    // MARK: - Phase 4: Test Specifications

    public func executePhase4Tests(features: [String]) async throws -> String {
        let featureList = features.joined(separator: "\n- ")
        let prompt = String(format: PRDConstants.Phase4.template, featureList)
        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: PRDConstants.DefaultValues.phase4ThinkingMode
        )

        return response
    }

    // MARK: - Phase 5: Technical Requirements

    public func executePhase5Requirements(context: String) async throws -> String {
        let prompt = String(format: PRDConstants.Phase5.template, context)
        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: PRDConstants.DefaultValues.phase5ThinkingMode
        )

        return response
    }

    // MARK: - Phase 6: Deployment Configuration

    public func executePhase6Deployment() async throws -> String {
        let (response, _) = try await orchestrator.chat(
            message: PRDConstants.Phase6.template,
            useAppleIntelligence: true,
            thinkingMode: PRDConstants.DefaultValues.phase6ThinkingMode
        )

        return response
    }
}