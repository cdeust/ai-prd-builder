import Foundation
import AIBridge

/// Handles various chat commands
public struct CommandHandlers {

    // MARK: - Help Command

    public static func displayHelp() {
        print(CommandConstants.HelpText.commands)
    }

    // MARK: - Glossary Commands

    public static func handleGlossary(_ args: [String], orchestrator: Orchestrator) async {
        let subcommand = CommandParser.extractSubcommand(from: args)

        switch subcommand {
        case CommandConstants.Glossary.list:
            await displayGlossaryEntries(orchestrator)
        case CommandConstants.Glossary.add:
            displayGlossaryAddInfo()
        default:
            displayGlossaryUsage()
        }
    }

    private static func displayGlossaryEntries(_ orchestrator: Orchestrator) async {
        let items = await orchestrator.listGlossary()

        if items.isEmpty {
            print(CommandConstants.Messages.glossaryEmpty)
        } else {
            print(CommandConstants.Messages.glossaryHeader)
            for entry in items {
                print(String(format: CommandConstants.Format.glossaryEntry, entry.acronym, entry.definition))
            }
        }
    }

    private static func displayGlossaryAddInfo() {
        print(CommandConstants.Messages.glossaryAddInfo)
    }

    private static func displayGlossaryUsage() {
        print(CommandConstants.Usage.glossary)
    }

    // MARK: - Thinking Mode Commands

    public static func handleThinking(
        _ args: [String],
        currentMode: Orchestrator.ThinkingMode,
        orchestrator: Orchestrator
    ) async -> Orchestrator.ThinkingMode {

        let subcommand = CommandParser.extractSubcommand(from: args)

        switch subcommand {
        case nil:
            displayCurrentThinkingMode(currentMode)
            return currentMode

        case CommandConstants.Thinking.list:
            displayAvailableThinkingModes(currentMode)
            return currentMode

        case CommandConstants.Thinking.show:
            displayThinkingState(orchestrator)
            return currentMode

        case CommandConstants.Thinking.guide:
            displayThinkingGuide(args)
            return currentMode

        default:
            return handleThinkingModeChange(subcommand!, currentMode: currentMode)
        }
    }

    private static func displayCurrentThinkingMode(_ mode: Orchestrator.ThinkingMode) {
        print("\(CommandConstants.Messages.currentThinkingMode)\(mode.rawValue)")
        print(CommandConstants.Usage.thinking)
    }

    private static func displayAvailableThinkingModes(_ currentMode: Orchestrator.ThinkingMode) {
        print(CommandConstants.Messages.availableThinkingModes)
        for mode in Orchestrator.ThinkingMode.allCases {
            let current = mode == currentMode ? CommandConstants.Format.currentIndicator : ""
            let alias = ThinkingModeHelper.getShortAlias(mode)
            print(String(format: CommandConstants.Format.thinkingMode, mode.rawValue, alias, current))
        }
    }

    private static func displayThinkingState(_ orchestrator: Orchestrator) {
        let thoughtProcess = orchestrator.getThoughtProcess()
        print(ThinkingModeHelper.formatThoughtProcess(thoughtProcess))
    }

    private static func displayThinkingGuide(_ args: [String]) {
        let additionalArgs = CommandParser.extractAdditionalArgs(from: args)

        if let modeString = additionalArgs.first,
           let mode = ThinkingModeHelper.parseThinkingMode(modeString) {
            print(ThinkingModeHelper.getUsageGuide(mode))
        } else {
            print(CommandConstants.Usage.thinkingGuide)
            print(CommandConstants.Usage.thinkingGuideExample)
        }
    }

    private static func handleThinkingModeChange(
        _ modeString: String,
        currentMode: Orchestrator.ThinkingMode
    ) -> Orchestrator.ThinkingMode {

        if let newMode = ThinkingModeHelper.parseThinkingMode(modeString) {
            print("\(CommandConstants.Messages.thinkingModeSet)\(newMode.rawValue)")
            print(ThinkingModeHelper.describeThinkingMode(newMode))
            return newMode
        } else {
            displayInvalidThinkingMode(modeString)
            return currentMode
        }
    }

    private static func displayInvalidThinkingMode(_ attempted: String) {
        print("\(CommandConstants.Messages.invalidThinkingMode)\(attempted)")
        print(CommandConstants.Messages.availableModes)
        for mode in Orchestrator.ThinkingMode.allCases {
            let alias = ThinkingModeHelper.getShortAlias(mode)
            print(String(format: CommandConstants.Format.thinkingModeSimple, alias, mode.rawValue))
        }
    }
}