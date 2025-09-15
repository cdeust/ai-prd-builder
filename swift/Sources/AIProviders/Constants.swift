import Foundation

public enum AIProviderConstants {

    // MARK: - HTTP Methods
    public enum HTTPMethods {
        public static let post = "POST"
        public static let get = "GET"
    }

    // MARK: - Model Names
    public enum Models {
        public static let openAIDefault = "gpt-5"
        public static let anthropicDefault = "claude-4-opus"
        public static let geminiDefault = "gemini-2.5-flash"
    }
    
    // MARK: - API Endpoints
    public enum Endpoints {
        public static let openAI = "https://api.openai.com/v1/chat/completions"
        public static let anthropic = "https://api.anthropic.com/v1/messages"
        public static let geminiBase = "https://generativelanguage.googleapis.com/v1beta/models"
    }
    
    // MARK: - Default Configuration
    public enum Defaults {
        public static let maxTokens = 4096
        public static let temperature = 0.7
        public static let anthropicVersion = "2023-06-01"
    }
    
    // MARK: - Environment Variable Keys
    public enum EnvironmentKeys {
        public static let openAI = "OPENAI_API_KEY"
        public static let anthropic = "ANTHROPIC_API_KEY"
        public static let gemini = "GEMINI_API_KEY"
    }
    
    // MARK: - Provider Keys
    public enum ProviderKeys {
        public static let appleOnDevice = "apple_on_device"
        public static let applePCC = "apple_pcc"
        public static let openAI = "openai"
        public static let anthropic = "anthropic"
        public static let gemini = "gemini"
    }
    
    // MARK: - HTTP Headers
    public enum Headers {
        public static let contentType = "Content-Type"
        public static let applicationJSON = "application/json"
        public static let authorization = "Authorization"
        public static let anthropicAPIKey = "x-api-key"
        public static let anthropicVersion = "anthropic-version"
    }
    
    // MARK: - Request Body Keys
    public enum RequestKeys {
        public static let model = "model"
        public static let messages = "messages"
        public static let maxTokens = "max_tokens"
        public static let temperature = "temperature"
        public static let role = "role"
        public static let content = "content"
        public static let system = "system"
        public static let contents = "contents"
        public static let parts = "parts"
        public static let text = "text"
        public static let generationConfig = "generationConfig"
        public static let maxOutputTokens = "maxOutputTokens"
    }

    // MARK: - Response Keys
    public enum ResponseKeys {
        public static let choices = "choices"
        public static let message = "message"
        public static let content = "content"
        public static let candidates = "candidates"
        public static let parts = "parts"
        public static let text = "text"
    }

    // MARK: - Role Values
    public enum RoleValues {
        public static let assistant = "assistant"
        public static let user = "user"
        public static let system = "system"
        public static let model = "model" // For Gemini
    }

    // MARK: - Bearer Token
    public enum Authorization {
        public static let bearerPrefix = "Bearer "
    }

    // MARK: - Apple Provider Names
    public enum AppleProviders {
        public static let onDeviceName = "apple_on_device"
        public static let pccName = "apple_pcc"
        public static let onDeviceDomain = "AppleOnDevice"
        public static let pccDomain = "ApplePCC"
    }

    // MARK: - Error Messages
    public enum ErrorMessages {
        // Provider configuration errors
        public static let notConfigured = "AI provider is not configured. Please set API key."
        public static let invalidAPIKey = "Invalid API key provided."
        public static let invalidInput = "Invalid input provided to AI provider."

        // Network and response errors
        public static let networkErrorFormat = "Network error: %@"
        public static let invalidResponse = "Invalid response from AI provider."
        public static let serverErrorFormat = "Server error: %@"

        // Rate limiting errors
        public static let rateLimitExceeded = "Rate limit exceeded. Please try again later."
        public static let tokenLimitExceeded = "Token limit exceeded. Please shorten your message."

        // Apple specific errors
        public static let appleIntelligenceNotAvailable = "Apple Intelligence not available on this device"
        public static let appleIntelligenceNotAvailablePCC = "Apple Intelligence not available"
        public static let foundationModelsRequirement = "Foundation Models requires macOS 16.0 or iOS 26.0"
        public static let foundationModelsFrameworkNotAvailable = "FoundationModels framework not available. Please ensure you're building on macOS 16+ with Xcode 16+"
        public static let failedToLoadConfiguration = "Failed to load configuration: %@"
    }

    // MARK: - Formatting
    public enum Formatting {
        public static let newlineDouble = "\n\n"
        public static let newline = "\n"
        public static let colonSpace = ": "
        public static let empty = ""
    }

    // MARK: - Queue Labels
    public enum QueueLabels {
        public static let repositoryQueue = "com.ai.provider.repository"
    }

    // MARK: - Device Capabilities
    public enum DeviceCapabilities {
        public static let hardwareKey = "hw.optional.arm64"
        public static let iosVersion = "iOS"
        public static let osVersionFormat = "%d.%d"
    }

    // MARK: - URL Query
    public enum URLQuery {
        public static let keyParameter = "key"
        public static let generateContentPath = ":generateContent"
    }

    // MARK: - Routing Comments
    public enum RoutingComments {
        public static let bestForJSON = "Best for JSON"
        public static let goodForLongContext = "GPT good for long context"
        public static let claudeBestForJSON = "Claude best for JSON"
    }

    // MARK: - Routing Decisions
    public enum RoutingDecisions {
        public static let routingDecisionHeader = "📍 Routing Decision:\n"
        public static let contentSizeFormat = "  Content size: %d chars\n"
        public static let needsJSONFormat = "  Needs JSON: %@\n"
        public static let privacyModeFormat = "  Privacy mode: %@\n"
        public static let appleIntelligenceFormat = "  Apple Intelligence: %@\n"
        public static let externalAllowedFormat = "  External allowed: %@\n"
        public static let routeChainFormat = "  Route chain: %@\n"
        public static let onDeviceMessage = "  ✅ Using on-device for privacy & speed"
        public static let pccMessage = "  ☁️ Using PCC for privacy-preserved cloud processing"
        public static let externalMessage = "  🌐 Using external API for advanced capabilities"
        public static let enabled = "enabled"
        public static let disabled = "disabled"
        public static let prioritized = "prioritized"
        public static let normal = "normal"
        public static let arrow = " → "
    }

    // MARK: - Route Descriptions
    public enum RouteDescriptions {
        public static let appleOnDevice = "Apple FM (on-device)"
        public static let applePCC = "Apple PCC"
        public static let apiSuffix = " API"
    }

    // MARK: - Capability Names
    public enum CapabilityNames {
        public static let json = "json"
        public static let longContext = "long_context"
        public static let realtime = "realtime"
    }

    // MARK: - HTTP Status Codes
    public enum StatusCodes {
        public static let success = 200
        public static let unauthorized = 401
        public static let forbidden = 403
        public static let tooManyRequests = 429
        public static let serverErrorStart = 500
        public static let serverErrorEnd = 599
    }

    // MARK: - API Configuration Keys
    public enum ConfigKeys {
        public static let apiKey = "api_key"
        public static let maxTokens = "max_tokens"
    }

    // MARK: - Code Analysis
    public enum CodeAnalysis {
        public static let defaultPrompt = "Analyze this code for potential improvements, bugs, and best practices."
        public static let systemRole = "You are a code analysis expert."
        public static let codeBlockPrefix = "\n\nCode:\n```\n"
        public static let codeBlockSuffix = "\n```"
    }
}