import Foundation

public enum AIProviderConstants {
    
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
    
    // MARK: - HTTP Status Codes
    public enum StatusCodes {
        public static let success = 200
        public static let unauthorized = 401
        public static let forbidden = 403
        public static let tooManyRequests = 429
        public static let serverErrorStart = 500
        public static let serverErrorEnd = 599
    }
}