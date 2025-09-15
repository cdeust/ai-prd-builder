import Foundation

/// Constants for the Apple Intelligence Orchestrator
public enum OrchestratorConstants {

    // MARK: - Application Info

    public enum App {
        public static let title = "🚀 Privacy-First AI Orchestrator"
        public static let separator = "================================="
        public static let privacyFlow = "Apple Foundation Models → PCC → External (if allowed)"
        public static let creatingMessage = "Creating AIOrchestrator..."
        public static let createdMessage = "AIOrchestrator created"
        public static let thankYouMessage = "\n👋 Thank you for using the AI Orchestrator!"
    }

    // MARK: - Privacy Messages

    public enum Privacy {
        public static let externalEnabled = "⚠️  External providers enabled (use only when necessary)"
        public static let privacyMode = "🔒 Privacy mode: Only Apple FM, PCC, and local models"
        public static let availableProviders = "📦 Available AI Providers (privacy-first order):"
        public static let policyHeader = "\n🔐 Privacy Policy:"
        public static let policyItems = [
            "  1. Apple Foundation Models (on-device, no data leaves)",
            "  2. Private Cloud Compute (Apple servers, verifiable privacy)",
            "  3. External APIs (only for complex/long context if --allow-external)"
        ]
    }

    // MARK: - Provider Indicators

    public enum ProviderIndicator {
        public static let onDevice = " 🏠 (on-device)"
        public static let privacyPreserved = " ☁️ (privacy-preserved)"
        public static let external = " 🌐 (external)"
        public static let disabled = " ❌ (disabled)"
    }

    // MARK: - Commands

    public enum Commands {
        public static let interactive = "interactive"
        public static let help = "--help"
        public static let helpShort = "-h"
        public static let chat = "chat"
        public static let prd = "prd"
        public static let session = "session"
        public static let exit = "exit"
    }

    // MARK: - Command Line Arguments

    public enum Arguments {
        public static let allowExternal = "--allow-external"
        public static let appleFirst = "--apple-first"
    }

    // MARK: - Environment Variables

    public enum Environment {
        public static let allowExternalProviders = "ALLOW_EXTERNAL_PROVIDERS"
        public static let appleIntelligenceFirst = "APPLE_INTELLIGENCE_FIRST"
        public static let metalDeviceWrapper = "METAL_DEVICE_WRAPPER_TYPE"
        public static let metalDebugError = "METAL_DEBUG_ERROR_MODE"
    }

    // MARK: - Session Messages

    public enum Session {
        public static let started = "🆕 Session started: "
        public static let newSession = "New session started: "
    }

    // MARK: - Processing Messages

    public enum Processing {
        public static let statusPrefix = "⏳ "
        public static let processingMessage = "Processing your message..."
        public static let stillWaiting = "   ⚠️  Still waiting... This is taking longer than usual."
        public static let appleIntelligenceDelay = "   (Apple Intelligence can take 30-60 seconds on first use)"
        public static let completedPrefix = "   ✓ Completed in "
        public static let secondsSuffix = " seconds"
        public static let aiResponsePrefix = "\n[🤖 "
        public static let aiResponseSuffix = "] "
    }

    // MARK: - PRD Generation

    public enum PRD {
        public static let header = "\n📋 PRD Generator (Iterative Enrichment)"
        public static let separator = "========================================"
        public static let prompt = "Describe what you want to build:"
        public static let noInput = "No input provided"
        public static let documentHeader = "# PRODUCT REQUIREMENTS DOCUMENT\n\n"

        // Phase messages
        public static let phase1 = "\n📝 Phase 1: Creating initial PRD structure..."
        public static let phase2 = "\n🔍 Phase 2: Enriching features with details..."
        public static let phase3 = "\n⚙️ Phase 3: Adding technical specifications..."
        public static let phase4 = "\n📊 Phase 4: Defining non-functional requirements..."
        public static let phase5 = "\n🚀 Phase 5: Deployment and infrastructure planning..."
        public static let phase6 = "\n✅ Phase 6: Final validation and completeness check..."

        public static let complete = "\n✅ PRD generation complete!"
        public static let yamlHeader = "\n📄 Here's your complete PRD in YAML format:"
        public static let yamlSeparator = "\n" + String(repeating: "=", count: 60) + "\n"
    }

    // MARK: - Progress Bar

    public enum ProgressBar {
        public static let filledChar = "█"
        public static let emptyChar = "░"
        public static let barLength = 20
        public static let format = "[%@] %d%% (%d/%d)"
    }

    // MARK: - Timing

    public enum Timing {
        public static let warningThreshold: TimeInterval = 30.0
        public static let displayThreshold: TimeInterval = 5.0
        public static let elapsedFormat = "%.1f"
    }

    // MARK: - UI Elements

    public enum UI {
        public static let inputPrompt = "> "
        public static let bullet = "  • "
        public static let unknownCommand = "Unknown command: "
    }
}