import Foundation

/// Constants for command-line interface commands and subcommands
public enum CommandConstants {

    // MARK: - Main Commands

    public enum Commands {
        public static let help = "/help"
        public static let glossary = "/glossary"
        public static let thinking = "/thinking"
        public static let exit = "exit"
    }

    // MARK: - Glossary Subcommands

    public enum Glossary {
        public static let list = "list"
        public static let add = "add"
        public static let search = "search"
        public static let clear = "clear"
    }

    // MARK: - Thinking Subcommands

    public enum Thinking {
        public static let list = "list"
        public static let show = "show"
        public static let guide = "guide"
        public static let reset = "reset"
        public static let history = "history"
    }

    // MARK: - Thinking Mode Aliases

    public enum ThinkingModes {
        public static let chain = "chain"
        public static let parallel = "parallel"
        public static let divergent = "divergent"
        public static let convergent = "convergent"
        public static let critical = "critical"
        public static let analogy = "analogy"
        public static let reverse = "reverse"
        public static let socratic = "socratic"
        public static let first = "first"
        public static let systems = "systems"
        public static let auto = "auto"

        public static let allAliases = [
            chain, parallel, divergent, convergent, critical,
            analogy, reverse, socratic, first, systems, auto
        ]
    }

    // MARK: - Messages

    public enum Messages {
        public static let unknownCommand = "❌ Unknown command. Type /help for commands."
        public static let invalidThinkingMode = "❌ Unknown thinking mode: "
        public static let thinkingModeSet = "✅ Thinking mode set to: "
        public static let glossaryEmpty = "ℹ️ Glossary is empty"
        public static let glossaryAddInfo = "ℹ️ Glossary entries are loaded from configuration file. Edit Glossary.yaml to add entries."
        public static let glossaryHeader = "📚 Glossary entries:"
        public static let processingMessage = "Processing your message..."
        public static let chatModeActive = "Chat mode active"
        public static let currentThinkingMode = "Current thinking mode: "
        public static let availableThinkingModes = "🧠 Available Thinking Modes:"
        public static let availableModes = "Available modes:"
        public static let thinkingPrefix = "🧠 Using "
        public static let thinkingSuffix = " thinking..."
        public static let welcomeMessage = "💬 Chat Mode (Acronym-aware)"
        public static let welcomeInstructions = "Type '/help' for commands. Type 'exit' to return to the main menu."
        public static let domainPrefix = "Domain: product (default). Glossary: "
        public static let glossaryNone = "none"
    }

    // MARK: - Usage Messages

    public enum Usage {
        public static let glossary = "Usage: /glossary [list|add]"
        public static let thinking = "Usage: /thinking [list|show|guide|<mode>]"
        public static let thinkingGuide = "Usage: /thinking guide <mode>"
        public static let thinkingGuideExample = "Example: /thinking guide critical"
    }

    // MARK: - Display Formats

    public enum Format {
        public static let glossaryEntry = "  - %@: %@"  // acronym: definition
        public static let thinkingMode = "  - %@ [%@]%@"  // mode, alias, current
        public static let thinkingModeSimple = "  - %@: %@"  // alias: mode
        public static let elapsedTime = "   ✓ Completed in %.1f seconds"
        public static let providerResponse = "\n[🤖 %@] %@\n"  // provider, response
        public static let currentIndicator = " (current)"
        public static let inputPrompt = "> "
    }

    // MARK: - Thresholds

    public enum Thresholds {
        public static let longResponseTime: TimeInterval = 5.0
        public static let glossaryPreviewCount = 8
    }

    // MARK: - Help Text

    public enum HelpText {
        public static let commands = """
        Commands:
          /thinking [mode]     - Set thinking mode (chain, parallel, divergent, critical, etc.)
          /thinking list       - List available thinking modes
          /thinking show       - Show current thinking state
          /thinking guide      - Show usage guide for modes
          /glossary list       - List glossary entries
          exit                 - Exit chat mode
        """

        public static let mainMenu = """
        =================================
        🧭 AI Orchestrator - Interactive Mode
        =================================
        Commands:
          chat       Chat with the AI assistant
          prd        Generate Product Requirements Document
          session    Start a new session
          exit       Quit

        Tips:
          - This tool prioritizes privacy: Apple Foundation Models → PCC → External (if allowed)
          - Use '--allow-external' to enable external providers
          - Type any message to chat directly
        """
    }

    // MARK: - Separators

    public enum Separators {
        public static let glossaryJoiner = ", "
        public static let glossaryFormat = "="
    }

    // MARK: - UI Prefixes

    public enum UIPrefix {
        public static let success = "✅ "
        public static let error = "❌ "
    }
}