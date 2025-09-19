import Foundation
import ArgumentParser

/// Command-line argument parser for the AI Orchestrator
public struct CommandLineArgumentParser {

    /// Configuration parsed from command-line arguments
    public struct Configuration {
        public let allowExternal: Bool
        public let verbose: Bool
        public let apiKeys: APIKeys
        public let command: Command?
        public let maxTokens: Int
        public let temperature: Double
        public let outputFormat: OutputFormat
        public let sessionId: String?
        public let configPath: String?

        /// API Keys configuration
        public struct APIKeys {
            public let openAI: String?
            public let anthropic: String?
            public let gemini: String?

            public init(openAI: String? = nil, anthropic: String? = nil, gemini: String? = nil) {
                self.openAI = openAI ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
                self.anthropic = anthropic ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
                self.gemini = gemini ?? ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
            }
        }

        /// Available commands
        public enum Command: String, CaseIterable {
            case interactive
            case chat
            case prd
            case openapi
            case test
            case validate
            case analyze
            case help
            case version

            public var description: String {
                switch self {
                case .interactive:
                    return "Start interactive mode with real-time feedback"
                case .chat:
                    return "Single chat interaction with the AI"
                case .prd:
                    return "Generate a Product Requirements Document"
                case .openapi:
                    return "Generate OpenAPI 3.1.0 specification"
                case .test:
                    return "Generate test data and scenarios"
                case .validate:
                    return "Validate generated specifications"
                case .analyze:
                    return "Analyze existing codebase"
                case .help:
                    return "Show help information"
                case .version:
                    return "Show version information"
                }
            }
        }

        /// Output format options
        public enum OutputFormat: String, CaseIterable {
            case text
            case json
            case yaml
            case markdown

            public var fileExtension: String {
                switch self {
                case .text: return "txt"
                case .json: return "json"
                case .yaml: return "yaml"
                case .markdown: return "md"
                }
            }
        }
    }

    /// Parse command-line arguments
    public static func parse() -> Configuration {
        let arguments = ProcessInfo.processInfo.arguments

        // Parse boolean flags
        let allowExternal = arguments.contains("--allow-external") || arguments.contains("-e")
        let verbose = arguments.contains("--verbose") || arguments.contains("-v")

        // Parse command
        let command = parseCommand(from: arguments)

        // Parse numeric values
        let maxTokens = parseIntValue(from: arguments, flag: "--max-tokens") ?? 50000
        let temperature = parseDoubleValue(from: arguments, flag: "--temperature") ?? 0.7

        // Parse string values
        let sessionId = parseStringValue(from: arguments, flag: "--session")
        let configPath = parseStringValue(from: arguments, flag: "--config")

        // Parse output format
        let outputFormat = parseOutputFormat(from: arguments)

        // Parse API keys
        let apiKeys = parseAPIKeys(from: arguments)

        return Configuration(
            allowExternal: allowExternal,
            verbose: verbose,
            apiKeys: apiKeys,
            command: command,
            maxTokens: maxTokens,
            temperature: temperature,
            outputFormat: outputFormat,
            sessionId: sessionId,
            configPath: configPath
        )
    }

    // MARK: - Private Parsing Methods

    private static func parseCommand(from arguments: [String]) -> Configuration.Command? {
        // Skip first argument (program name)
        guard arguments.count > 1 else { return nil }

        let commandString = arguments[1]

        // Check if it's a flag instead of a command
        if commandString.starts(with: "-") {
            return nil
        }

        return Configuration.Command(rawValue: commandString)
    }

    private static func parseIntValue(from arguments: [String], flag: String) -> Int? {
        guard let index = arguments.firstIndex(of: flag),
              index + 1 < arguments.count,
              let value = Int(arguments[index + 1]) else {
            return nil
        }
        return value
    }

    private static func parseDoubleValue(from arguments: [String], flag: String) -> Double? {
        guard let index = arguments.firstIndex(of: flag),
              index + 1 < arguments.count,
              let value = Double(arguments[index + 1]) else {
            return nil
        }
        return value
    }

    private static func parseStringValue(from arguments: [String], flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag),
              index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }

    private static func parseOutputFormat(from arguments: [String]) -> Configuration.OutputFormat {
        if let format = parseStringValue(from: arguments, flag: "--format"),
           let outputFormat = Configuration.OutputFormat(rawValue: format) {
            return outputFormat
        }
        return .text
    }

    private static func parseAPIKeys(from arguments: [String]) -> Configuration.APIKeys {
        return Configuration.APIKeys(
            openAI: parseStringValue(from: arguments, flag: "--openai-key"),
            anthropic: parseStringValue(from: arguments, flag: "--anthropic-key"),
            gemini: parseStringValue(from: arguments, flag: "--gemini-key")
        )
    }

    // MARK: - Help and Usage

    public static func printHelp() {
        print("""
        AI Orchestrator - Privacy-First AI Processing

        USAGE:
            ai-orchestrator [COMMAND] [OPTIONS]

        COMMANDS:
            interactive    Start interactive mode with real-time feedback
            chat          Single chat interaction with the AI
            prd           Generate a Product Requirements Document
            openapi       Generate OpenAPI 3.1.0 specification
            test          Generate test data and scenarios
            validate      Validate generated specifications
            analyze       Analyze existing codebase
            help          Show this help information
            version       Show version information

        OPTIONS:
            -e, --allow-external         Allow external API providers
            -v, --verbose               Enable verbose output
            --max-tokens <number>       Maximum tokens for response (default: 50000)
            --temperature <number>      Temperature for AI responses (0.0-1.0, default: 0.7)
            --format <format>           Output format: text, json, yaml, markdown (default: text)
            --session <id>              Resume a specific session
            --config <path>             Path to configuration file
            --openai-key <key>          OpenAI API key (overrides environment)
            --anthropic-key <key>       Anthropic API key (overrides environment)
            --gemini-key <key>          Gemini API key (overrides environment)

        EXAMPLES:
            ai-orchestrator interactive
            ai-orchestrator chat "What is Swift?"
            ai-orchestrator prd --format yaml
            ai-orchestrator analyze /path/to/project --verbose
            ai-orchestrator --allow-external chat "Complex question"

        PRIVACY:
            By default, the orchestrator uses Apple's on-device models and Private Cloud Compute.
            External providers are only used when explicitly enabled with --allow-external.
        """)
    }

    public static func printVersion() {
        print("""
        AI Orchestrator v2.0.0
        Built with Swift 5.9
        Requires macOS 14.0+ (MLX/Metal support)
        Requires macOS 15.1+ (Apple Intelligence features)
        """)
    }

    /// Validate configuration
    public static func validate(_ config: Configuration) -> [String] {
        var warnings: [String] = []

        if config.allowExternal {
            if config.apiKeys.openAI == nil && config.apiKeys.anthropic == nil && config.apiKeys.gemini == nil {
                warnings.append("⚠️  External providers enabled but no API keys configured")
            }
        }

        if config.temperature < 0.0 || config.temperature > 1.0 {
            warnings.append("⚠️  Temperature should be between 0.0 and 1.0")
        }

        if config.maxTokens < 1000 || config.maxTokens > 200000 {
            warnings.append("⚠️  Max tokens should be between 1000 and 200000 (recommended: 30000-50000 for PRDs)")
        }

        return warnings
    }
}