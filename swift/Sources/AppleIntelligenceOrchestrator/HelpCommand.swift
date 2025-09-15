import Foundation

/// Handles help command display and usage information
public struct HelpCommand {

    /// Displays the main help information for the orchestrator
    public static func printHelp() {
        print(buildHelpText())
    }

    // MARK: - Private Helpers

    private static func buildHelpText() -> String {
        return """

        \(usageSection())

        \(commandsSection())

        \(privacyOptionsSection())

        \(prdOptionsSection())

        \(environmentVariablesSection())

        \(examplesSection())

        \(providerPrioritySection())

        """
    }

    private static func usageSection() -> String {
        return "Usage: ai-orchestrator [command] [options]"
    }

    private static func commandsSection() -> String {
        return """
        Commands:
          generate-prd      Generate a Product Requirements Document
          interactive       Run in interactive mode (default)
          --help, -h       Show this help message
        """
    }

    private static func privacyOptionsSection() -> String {
        return """
        Privacy Options:
          --allow-external  Allow external API providers (Anthropic, OpenAI, Gemini)
                          By default, only Apple FM, PCC, and local models are used
          --apple-first    Prioritize Apple Intelligence for all operations
        """
    }

    private static func prdOptionsSection() -> String {
        return """
        Options for generate-prd:
          --feature, -f    Feature description (required)
          --context, -c    Context or problem statement
          --priority, -p   Priority level (critical/high/medium/low)
          --requirement, -r Add a requirement (can be used multiple times)
        """
    }

    private static func environmentVariablesSection() -> String {
        return """
        Environment Variables:
          ALLOW_EXTERNAL_PROVIDERS=true   Enable external providers
          ANTHROPIC_API_KEY               API key for Claude
          OPENAI_API_KEY                  API key for GPT
          GEMINI_API_KEY                  API key for Gemini
        """
    }

    private static func examplesSection() -> String {
        return """
        Examples:
          # Privacy-first (default)
          ai-orchestrator generate-prd -f "User authentication" -p high

          # Allow external providers for complex tasks
          ai-orchestrator --allow-external generate-prd -f "Complex system" -p critical

          # Use Apple Intelligence (default) or cloud providers
          ai-orchestrator --allow-external interactive
        """
    }

    private static func providerPrioritySection() -> String {
        return """
        Provider Priority:
          1. Apple Intelligence Writing Tools (when available)
          2. Apple Foundation Models (on-device)
          3. Private Cloud Compute (privacy-preserved)
          4. External APIs (if allowed and necessary)
        """
    }
}