import Foundation

/// Parses user input to identify commands and arguments
public struct CommandParser {

    public enum CommandType {
        case help
        case glossary
        case thinking
        case exit
        case unknown
        case notCommand
    }

    public struct ParsedCommand {
        public let type: CommandType
        public let args: [String]
        public let raw: String

        public init(type: CommandType, args: [String], raw: String) {
            self.type = type
            self.args = args
            self.raw = raw
        }
    }

    /// Parse user input into a command structure
    public static func parse(_ input: String) -> ParsedCommand {
        // Check for exit first (special case, not a slash command)
        if input.lowercased() == "exit" {
            return ParsedCommand(type: .exit, args: [], raw: input)
        }

        // Check if it's a command (starts with /)
        guard input.hasPrefix("/") else {
            return ParsedCommand(type: .notCommand, args: [], raw: input)
        }

        // Parse the command and arguments
        let parts = input.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        let command = parts.first?.lowercased() ?? ""
        let args = parts.dropFirst().map { String($0) }

        let type: CommandType = switch command {
        case "/help": .help
        case "/glossary": .glossary
        case "/thinking": .thinking
        default: .unknown
        }

        return ParsedCommand(type: type, args: args, raw: input)
    }

    /// Check if input is a command
    public static func isCommand(_ input: String) -> Bool {
        return input.hasPrefix("/") || input.lowercased() == "exit"
    }

    /// Extract subcommand from arguments
    public static func extractSubcommand(from args: [String]) -> String? {
        return args.first?.lowercased()
    }

    /// Extract additional arguments after subcommand
    public static func extractAdditionalArgs(from args: [String]) -> [String] {
        return Array(args.dropFirst())
    }
}