import Foundation

/// Constants for the AIBridge Orchestrator
public enum OrchestratorConstants {

    // MARK: - Default Values
    public enum Defaults {
        public static let domain = "default"
        public static let invalidConfiguration = "Invalid orchestrator configuration"
    }

    // MARK: - Separators and Formatting
    public enum Formatting {
        public static let newlineDouble = "\n\n"
        public static let newline = "\n"
        public static let comma = ", "
        public static let space = " "
        public static let questionMark = "?"
        public static let and = " and "
    }

    // MARK: - AI Provider Names

    public enum ProviderNames {
        public static let foundationModels = "Apple Foundation Models (On-Device)"
        public static let privateCloudCompute = "Apple Private Cloud Compute"
        public static let anthropic = "Anthropic Claude"
        public static let openai = "OpenAI GPT"
        public static let gemini = "Google Gemini"
    }

    // MARK: - Provider Display Names
    public enum ProviderDisplayNames {
        public static let foundationModels = "Apple Foundation Models (On-Device)"
        public static let privateCloudCompute = "Apple Private Cloud Compute"
        public static let anthropic = "Anthropic Claude"
        public static let openai = "OpenAI GPT"
        public static let gemini = "Google Gemini"
    }

    // MARK: - Provider Keys
    public enum ProviderKeys {
        public static let appleOnDevice = "apple-on-device"
        public static let applePCC = "apple-pcc"
    }

    // MARK: - Provider Messages
    public enum ProviderMessages {
        public static let initializeSuccess = "Providers initialized successfully"
        public static let initializeFailure = "Failed to initialize providers: %@"
    }

    // MARK: - Provider Priority

    public enum ProviderPriority {
        public static let foundationModels = 1      // Highest priority - on-device
        public static let privateCloudCompute = 2   // Privacy-preserved cloud
        public static let anthropic = 3             // External APIs only when needed
        public static let openai = 4
        public static let gemini = 5
    }

    // MARK: - Thinking Mode Names

    public enum ThinkingModeNames {
        public static let automatic = "automatic"
        public static let chainOfThought = "chain-of-thought"
        public static let parallelExploration = "parallel-exploration"
        public static let divergentThinking = "divergent-thinking"
        public static let convergentThinking = "convergent-thinking"
        public static let criticalAnalysis = "critical-analysis"
        public static let analogicalReasoning = "analogical-reasoning"
        public static let reverseEngineering = "reverse-engineering"
        public static let socraticMethod = "socratic-method"
        public static let firstPrinciples = "first-principles"
        public static let systemsThinking = "systems-thinking"
    }

    // MARK: - Thinking Mode Descriptions
    public enum ThinkingModeDescriptions {
        public static let automatic = "Automatically selects the best thinking mode"
        public static let chainOfThought = "Step-by-step logical reasoning"
        public static let parallelExploration = "Explores multiple approaches simultaneously"
        public static let divergentThinking = "Creative, expansive ideation"
        public static let convergentThinking = "Narrows down to the best solution"
        public static let criticalAnalysis = "Deep evaluation and critique"
        public static let analogicalReasoning = "Pattern matching and comparisons"
        public static let reverseEngineering = "Works backwards from the goal"
        public static let socraticMethod = "Question-driven exploration"
        public static let firstPrinciples = "Breaks down to fundamental truths"
        public static let systemsThinking = "Holistic, interconnected view"
    }

    // MARK: - Thinking Mode Emojis
    public enum ThinkingModeEmojis {
        public static let automatic = "🤖"
        public static let chainOfThought = "🔗"
        public static let parallelExploration = "🔀"
        public static let divergentThinking = "💭"
        public static let convergentThinking = "🎯"
        public static let criticalAnalysis = "🔍"
        public static let analogicalReasoning = "🔄"
        public static let reverseEngineering = "⏪"
        public static let socraticMethod = "❓"
        public static let firstPrinciples = "⚛️"
        public static let systemsThinking = "🌐"
    }

    // MARK: - Thinking Mode Analysis
    public enum ThinkingModeAnalysis {
        public static let comparisonWords = ["compare", "versus", "vs", "difference", "similar", "like", "unlike"]
        public static let creativeWords = ["create", "design", "imagine", "innovative", "creative", "brainstorm", "idea"]
        public static let technicalTerms = ["system", "architecture", "algorithm", "implementation", "framework", "protocol"]
        public static let strugglesLabel = "Struggles: %d"
        public static let uncertaintiesLabel = "Uncertainties: %d"
        public static let assumptionsLabel = "Assumptions: %d"
        public static let breakthroughsLabel = "Breakthroughs: %d"
        public static let noThoughtProcess = "No thought process recorded"
    }

    // MARK: - Glossary
    public enum Glossary {
        public static let loadFailed = "Failed to load glossary: %@"
        public static let domainLabel = "Domain: %@\n\n"
        public static let knownAcronymsLabel = "Known acronyms:\n"
        public static let entryFormat = "- %@: %@"
        public static let contextFormat = " (Context: %@)"
        public static let usageFormat = "\n  Usage: %@"
    }

    // MARK: - System Messages

    public enum SystemMessages {
        public static let defaultAssistant = "You are a helpful AI assistant."
        public static let thinkingModePrefix = "🧠 Using thinking mode: "
        public static let acronymPolicyHeader = "# Domain Glossary\n\n"
        public static let acronymPolicyInstructions = """
            The user may use acronyms. When responding:
            1. Use full terms first, then acronym: 'Product Requirements Document (PRD)'
            2. After first use, acronym alone is fine
            3. Be consistent throughout the response
            """
        public static let noGlossaryMessage = "No domain glossary configured."
    }

    // MARK: - Chat Messages

    public enum ChatMessages {
        public static let refinePrompt = "Please refine and improve the response for clarity and completeness."
        public static let providerInitializing = "Initializing AI providers..."
        public static let externalProvidersNotAllowed = "External providers not allowed by privacy configuration"
        public static let noProvidersAvailable = "No AI providers available"
        public static let messageEmpty = "Message cannot be empty"
    }

    // MARK: - PRD Generation

    public enum PRD {
        public static let generationPrompt = """
            Generate a comprehensive Product Requirements Document (PRD) for: %@

            Include the following sections:
            1. Executive Summary
            2. Product Vision & Goals
            3. Key Features & Requirements
            4. User Stories & Use Cases
            5. Technical Architecture
            6. Success Metrics
            7. Timeline & Milestones
            8. Risks & Mitigations

            Format as professional PRD with clear sections.
            """

        public static let yamlConversionPrompt = """
            Convert the following PRD to YAML format suitable for project configuration:

            %@

            Use this structure:
            ```yaml
            project:
              name:
              vision:
              goals:
              features:
                - name:
                  description:
                  priority:
              technical:
                architecture:
                stack:
              metrics:
              timeline:
            ```
            """
    }

    // MARK: - Thinking Mode Selection

    public enum ThinkingModeSelection {
        public static let analyzePrompt = """
            Analyze this request and determine the best thinking mode:
            "%@"

            Choose from:
            - chain-of-thought: Step-by-step logical reasoning
            - parallel-exploration: Multiple simultaneous approaches
            - divergent-thinking: Creative, expansive ideation
            - convergent-thinking: Narrowing to best solution
            - critical-analysis: Deep evaluation and critique
            - analogical-reasoning: Pattern matching and comparisons
            - reverse-engineering: Working backwards from goal
            - socratic-method: Question-driven exploration
            - first-principles: Breaking down to fundamentals
            - systems-thinking: Holistic interconnected view

            Respond with just the mode name.
            """
    }

    // MARK: - Error Messages

    public enum Errors {
        public static let sessionNotFound = "Session not found"
        public static let providerNotAvailable = "Provider not available: %@"
        public static let providerNotFound = "Provider not found: %@"
        public static let failedToInitialize = "Failed to initialize provider: %@"
        public static let noResponseReceived = "No response received from provider"
        public static let invalidThinkingMode = "Invalid thinking mode: %@"
        public static let noRouteAvailable = "No route available for the request"
        public static let externalNotAllowed = "External providers are not allowed by privacy configuration"
        public static let executionFailed = "Provider execution failed: %@"
    }

    // MARK: - Timing Constants

    public enum Timing {
        public static let shortMessageThreshold = 500
        public static let defaultTimeout: TimeInterval = 30.0
        public static let extendedTimeout: TimeInterval = 60.0
    }

    // MARK: - UI Indicators

    public enum UIIndicators {
        public static let thinking = "🤔"
        public static let success = "✅"
        public static let warning = "⚠️"
        public static let error = "❌"
        public static let info = "ℹ️"
        public static let brain = "🧠"
    }
}