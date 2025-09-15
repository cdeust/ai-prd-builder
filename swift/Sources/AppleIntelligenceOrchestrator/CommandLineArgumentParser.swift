import Foundation

/// Parses and processes command line arguments
public struct CommandLineArgumentParser {

    /// Configuration derived from command line arguments
    public struct Configuration {
        public let allowExternal: Bool
        public let appleFirst: Bool
        public let command: Command?

        public enum Command {
            case interactive
            case help
            case unknown(String)
        }
    }

    // MARK: - Public Interface

    /// Parses command line arguments into a configuration
    ///
    /// - Parameter arguments: The command line arguments to parse
    /// - Returns: A configuration object with parsed settings
    public static func parse(_ arguments: [String] = CommandLine.arguments) -> Configuration {
        let allowExternal = checkAllowExternal(arguments)
        let appleFirst = checkAppleFirst(arguments)
        let command = parseCommand(arguments)

        return Configuration(
            allowExternal: allowExternal,
            appleFirst: appleFirst,
            command: command
        )
    }

    // MARK: - Private Parsing Methods

    private static func checkAllowExternal(_ arguments: [String]) -> Bool {
        return arguments.contains(OrchestratorConstants.Arguments.allowExternal) ||
               ProcessInfo.processInfo.environment[OrchestratorConstants.Environment.allowExternalProviders] == "true"
    }

    private static func checkAppleFirst(_ arguments: [String]) -> Bool {
        return arguments.contains(OrchestratorConstants.Arguments.appleFirst) ||
               ProcessInfo.processInfo.environment[OrchestratorConstants.Environment.appleIntelligenceFirst] == "true"
    }

    private static func parseCommand(_ arguments: [String]) -> Configuration.Command? {
        guard arguments.count > 1 else { return nil }

        let command = arguments[1]

        switch command {
        case OrchestratorConstants.Commands.interactive:
            return .interactive

        case OrchestratorConstants.Commands.help,
             OrchestratorConstants.Commands.helpShort:
            return .help

        default:
            return .unknown(command)
        }
    }
}