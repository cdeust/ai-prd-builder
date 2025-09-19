import Foundation

// Entry point - calls the main orchestrator
Task {
    await AppleIntelligenceOrchestrator.runMain()
    exit(0)
}

RunLoop.main.run()