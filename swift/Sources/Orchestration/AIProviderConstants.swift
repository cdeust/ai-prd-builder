import Foundation

/// Constants for AI Provider management
public enum AIProviderConstants {

    public enum ProviderKeys {
        public static let openAI = "openai"
        public static let anthropic = "anthropic"
        public static let gemini = "gemini"
        public static let apple = "apple"
        public static let mlx = "mlx"
    }

    public enum ProviderNames {
        public static let openAI = "OpenAI"
        public static let anthropic = "Anthropic"
        public static let gemini = "Google Gemini"
        public static let apple = "Apple Foundation Models"
        public static let mlx = "MLX On-Device"
    }

    public enum ErrorMessages {
        public static let noProviderAvailable = "No AI provider available"
        public static let providerNotConfigured = "Provider not configured"
        public static let apiKeyMissing = "API key missing for provider"
        public static let externalProvidersDisabled = "External providers are disabled"
    }

    public enum EnvironmentKeys {
        public static let openAIKey = "OPENAI_API_KEY"
        public static let anthropicKey = "ANTHROPIC_API_KEY"
        public static let geminiKey = "GEMINI_API_KEY"
    }

    public enum Configuration {
        public static let maxRetries = 3
        public static let timeoutSeconds = 120.0  // Increased for larger responses
        public static let maxTokens = 50000  // 50K tokens for comprehensive PRDs
        public static let temperature = 0.7
    }

    public enum Defaults {
        public static let appleModel = "apple-foundation-model-2025"  // Apple's 2025 Foundation Model
        public static let appleEndpoint = "https://api.apple.com/v1"
        public static let maxTokens = 100000  // 100K tokens default for comprehensive outputs
        public static let temperature = 0.7

        // Default models for each provider (2025)
        public static let openAIModel = Models.gpt5  // Use GPT-5 (best available)
        public static let anthropicModel = Models.claudeOpus41  // Use Claude Opus 4.1 (latest)
        public static let geminiModel = Models.gemini25Pro  // Use Gemini 2.5 Pro (1M context!)
        public static let grokModel = Models.grok4  // Use Grok 4 (256K context)
    }

    public enum Endpoints {
        public static let openAIBase = "https://api.openai.com/v1"
        public static let anthropicBase = "https://api.anthropic.com/v1"
        public static let geminiBase = "https://generativelanguage.googleapis.com/v1"
    }

    public enum Models {
        // OpenAI Models (2025 - Released)
        public static let gpt5 = "gpt-5"  // GPT-5 - Released August 7, 2025
        public static let gpt41 = "gpt-4.1"  // GPT-4.1 - Released April 14, 2025
        public static let gpt4o = "gpt-4o"  // GPT-4 Omni model
        public static let o1 = "o1"  // OpenAI o1 reasoning model

        // Anthropic Models (2025 - Released)
        public static let claudeOpus41 = "claude-opus-4.1"  // Claude Opus 4.1 - Released August 5, 2025
        public static let claude4Opus = "claude-4-opus"  // Claude 4 Opus - Released May 2025
        public static let claude4Sonnet = "claude-4-sonnet"  // Claude 4 Sonnet - Released May 2025
        public static let claude37Sonnet = "claude-3.7-sonnet"  // Claude 3.7 Sonnet - Released Feb 24, 2025
        public static let claude4Haiku = "claude-4-haiku"  // Claude 4 Haiku (fast)

        // Google Models (2025 - Released)
        public static let gemini25Pro = "gemini-2.5-pro"  // Gemini 2.5 Pro - Released March 2025
        public static let gemini25Flash = "gemini-2.5-flash"  // Gemini 2.5 Flash
        public static let gemini20FlashThinking = "gemini-2.0-flash-thinking-exp"  // Thinking model

        // xAI Models (2025 - Released)
        public static let grok4 = "grok-4"  // Grok 4 - Released July 2025
        public static let grok3 = "grok-3"  // Grok 3 - Released Feb 2025
    }

    public enum TokenLimits {
        // Based on actual 2025 specifications

        // Apple (2025 specs from WWDC25)
        public static let appleOnDevice = 4096            // Apple on-device model: 4K context (confirmed)
        public static let appleServer = 128000            // Apple server model with PCC (estimated)

        // Anthropic (2025 - actual specs)
        public static let claudeOpus41 = 200000           // Claude Opus 4.1: 200K input, 32K output
        public static let claude4Models = 200000          // Claude 4 family: 200K context
        public static let claude37Sonnet = 200000         // Claude 3.7 Sonnet: 200K context

        // OpenAI (2025 - actual specs)
        public static let gpt5 = 400000                   // GPT-5: 400K context, 128K output
        public static let gpt41 = 256000                  // GPT-4.1: 256K context
        public static let o1 = 256000                     // O1: 256K context

        // Google Gemini (2025 - actual specs)
        public static let gemini25Pro = 1000000           // Gemini 2.5 Pro: 1M context (2M coming)
        public static let gemini25Flash = 1000000         // Gemini 2.5 Flash: 1M context
        public static let gemini25ProOutput = 64000       // Gemini 2.5 Pro: 64K output

        // xAI Grok (2025 - actual specs)
        public static let grok4 = 256000                  // Grok 4: 256K context
        public static let grok3 = 128000                  // Grok 3: 128K context

        // Local models
        public static let mlxLocal = 8192                 // MLX local models: typically 8K

        // PRD generation requirements
        public static let minimumForPRD = 30000
        public static let recommendedForPRD = 100000      // Updated based on modern capabilities
        public static let optimalForPRD = 200000          // For comprehensive PRDs
        public static let maximumForPRD = 400000          // Using GPT-5's full context
    }
}