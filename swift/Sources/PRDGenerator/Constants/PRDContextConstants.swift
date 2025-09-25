import Foundation

/// Constants for task context and assumptions
public enum PRDContextConstants {

    // MARK: - Context Assumptions
    public enum ContextAssumptions {
        public static let incremental = """
            Context Assumptions (Incremental Task):
            - Existing system architecture is in place
            - Authentication and user management exist
            - Database and core models are established
            - CI/CD pipeline is configured
            - Basic CRUD operations are implemented
            - Focus on the specific feature being added
            """

        public static let greenfield = """
            Context Assumptions (New Project):
            - Starting from scratch
            - Need to define core architecture
            - Establishing foundational components
            - Setting up development environment
            - Creating initial data models
            - Defining basic workflows
            """

        public static let bugFix = """
            Context Assumptions (Bug Fix):
            - System is mostly functional
            - Issue is localized to specific area
            - No major architectural changes needed
            - Existing tests may need updates
            - Focus on minimal code changes
            """

        public static let refactor = """
            Context Assumptions (Refactoring):
            - Functionality remains the same
            - Focus on code quality improvements
            - Tests should continue to pass
            - No new features being added
            - Performance or maintainability focus
            """

        public static let configuration = """
            Context Assumptions (Configuration):
            - Core system is functional
            - Focus on setup or deployment
            - No code logic changes
            - Environment-specific settings
            - Infrastructure or tooling updates
            """
    }

    // MARK: - Context Prefixes for Prompts
    public enum ContextPrefixes {
        public static let incremental = """
            IMPORTANT: This is an INCREMENTAL task on an existing system.
            Assume all basic infrastructure, auth, and core features exist.
            Focus ONLY on what's being added or changed by this specific task.

            """

        public static let greenfield = """
            NOTE: This appears to be a NEW PROJECT from scratch.
            Provide comprehensive specifications for the initial implementation.

            """

        public static let bugFix = """
            IMPORTANT: This is a BUG FIX task.
            Focus on identifying and fixing the specific issue.
            Minimize changes to working code.

            """

        public static let refactor = """
            IMPORTANT: This is a REFACTORING task.
            Functionality must remain the same.
            Focus on code quality and structure improvements.

            """

        public static let configuration = """
            IMPORTANT: This is a CONFIGURATION task.
            Focus on setup, deployment, or environment settings.

            """
    }

    // MARK: - Format Strings
    public enum FormatStrings {
        public static let listItem = "- %@"
        public static let numberedListItem = "%d. %@"
        public static let bulletPoint = "• %@"
        public static let backtickWrapper = "`%@`"
        public static let boldWrapper = "**%@**"
        public static let italicWrapper = "*%@*"
        public static let codeBlock = "```%@\n%@\n```"
        public static let markdownHeader1 = "# %@"
        public static let markdownHeader2 = "## %@"
        public static let markdownHeader3 = "### %@"
    }

    // MARK: - Content Formatting
    public enum ContentFormatting {
        public static let confidenceFormat = "\n\n**Confidence:** %d%%"
        public static let stackAwareFormat = "\n**Stack Aware:** Yes"
        public static let testFrameworkFormat = "\n**Test Framework:** %@"
        public static let pipelineFormat = "\n**Pipeline:** %@"
        public static let confidencePrefix = "**Confidence:** "
        public static let percentSuffix = "%"
        public static let additionalContextPrefix = "\n\nAdditional user context: "
        public static let prdSuffix = " - PRD"
    }

    // MARK: - Design Guidelines
    public enum DesignGuidelines {
        public static let header = "Design Guidelines:"
        public static let contextHeader = "Additional Context:"
        public static let mockupSectionTitle = "## Mockup-Based Requirements"
        public static let referencedFilesHeader = "### Referenced Mockup Files"
    }
}