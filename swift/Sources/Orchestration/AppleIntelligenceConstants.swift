import Foundation

/// Constants for Apple Intelligence features and services
public enum AppleIntelligenceConstants {

    // MARK: - Acceptance Criteria

    public enum AcceptanceCriteria {
        // Priority values
        public enum Priority {
            public static let mustHave = "must-have"
            public static let shouldHave = "should-have"
            public static let niceToHave = "nice-to-have"
            public static let critical = "critical"
        }

        // Category values
        public enum Category {
            public static let functional = "functional"
            public static let performance = "performance"
            public static let security = "security"
            public static let usability = "usability"
            public static let accessibility = "accessibility"
            public static let compliance = "compliance"
        }

        // Formatting
        public enum Formatting {
            public static let header = "## Acceptance Criteria\n\n"
            public static let categoryHeaderFormat = "### %@\n\n"
            public static let criterionFormat = "%d. **[%@] [Testable: %@]**\n"
            public static let givenFormat = "   - **Given:** %@\n"
            public static let whenFormat = "   - **When:** %@\n"
            public static let thenFormat = "   - **Then:** %@\n\n"
            public static let testableYes = "✓"
            public static let testableNo = "✗"
        }

        // Test Generation
        public enum TestGeneration {
            public static let header = "// Generated Test Cases\n\n"
            public static let functionTemplate = """
            func test%@() {
                // Given: %@
                // TODO: Set up test data and environment

                // When: %@
                // TODO: Execute the action

                // Then: %@
                // TODO: Assert expected outcome
                XCTAssertTrue(false, "Test not implemented")
            }

            """
            public static let givenComment = "// Given: %@"
            public static let whenComment = "// When: %@"
            public static let thenComment = "// Then: %@"
            public static let todoSetup = "// TODO: Set up test data and environment"
            public static let todoExecute = "// TODO: Execute the action"
            public static let todoAssert = "// TODO: Assert expected outcome"
            public static let notImplementedAssertion = "XCTAssertTrue(false, \"Test not implemented\")"
        }
    }

    // MARK: - Apple Intelligence Service

    public enum Service {
        // Metadata keys
        public enum MetadataKeys {
            public static let overallSentiment = "overall_sentiment"
            public static let sentimentSegments = "sentiment_segments"
            public static let entities = "entities"
            public static let dominantLanguage = "dominant_language"
            public static let languageHypotheses = "language_hypotheses"
            public static let originalLength = "original_length"
            public static let summaryLength = "summary_length"
            public static let compressionRatio = "compression_ratio"
            public static let keyPhrases = "key_phrases"
            public static let styleApplied = "style_applied"
            public static let prompt = "prompt"
            public static let unknown = "unknown"
            public static let none = "none"
        }

        // Text processing
        public enum TextProcessing {
            public static let bulletPointPrefix = "• "
            public static let sentenceSeparators = ".!?"
            public static let periodSuffix = "."
            public static let newline = "\n"
            public static let minimumPhraseLength = 3
            public static let defaultMaxSentences = 3
            public static let defaultMaxKeyPoints = 5
        }

        // Placeholder messages
        public enum Placeholders {
            public static let textGenerationPlaceholder = "[Text generation will be available with Foundation Models API]"
        }
    }

    // MARK: - Apple Intelligence Client

    public enum Client {
        // File and process management
        public enum FileManagement {
            public static let tempFileExtension = "txt"
            public static let textEditBundleId = "com.apple.TextEdit"
        }

        // Shell commands
        public enum ShellCommands {
            public static let bashPath = "/bin/bash"
            public static let bashFlag = "-c"
            public static let checkWritingTools = "ps aux | grep -i 'writing.*tools' | grep -v grep"
        }

        // Timing
        public enum Timing {
            public static let defaultTimeout: TimeInterval = 30.0
            public static let launchDelay: UInt64 = 1_000_000_000 // 1 second in nanoseconds
            public static let fileOpenDelay: UInt64 = 1_000_000_000
            public static let scriptDelay: Double = 0.5
            public static let processingDelay: Double = 3.0
        }

        // AppleScript components
        public enum AppleScript {
            public static let scriptTemplate = """
            tell application "System Events"
                tell process "TextEdit"
                    set frontmost to true

                    -- Select all text
                    keystroke "a" using command down
                    delay %f

                    -- Open Writing Tools (Cmd+Shift+W typically)
                    keystroke "w" using {command down, shift down}
                    delay 1

                    -- Navigate to the command
                    keystroke "%@"
                    delay %f
                    keystroke return

                    -- Wait for processing
                    delay %f

                    -- Copy the result
                    keystroke "a" using command down
                    delay %f
                    keystroke "c" using command down
                    delay %f

                    -- Get from clipboard
                    set resultText to the clipboard as string
                end tell
            end tell

            return resultText
            """

            public static let closeTextEditScript = """
            tell application "TextEdit"
                quit saving no
            end tell
            """
        }

        // PRD Generation
        public enum PRDGeneration {
            // Prompt template moved to PRDPrompts.swift

            public static let requirementsSeparator = ", "
            public static let sectionNumbers = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
            public static let sections = [
                "Executive Summary",
                "Problem Statement",
                "Success Metrics",
                "User Stories",
                "Functional Requirements",
                "Non-Functional Requirements",
                "Technical Considerations",
                "Acceptance Criteria",
                "Timeline",
                "Risks and Mitigation"
            ]
        }

        // Error messages
        public enum ErrorMessages {
            public static let failedToCreateScript = "Failed to create AppleScript"
        }
    }

    // MARK: - Formatting and Common Values

    public enum Common {
        public static let empty = ""
        public static let space = " "
        public static let newline = "\n"
        public static let doubleNewline = "\n\n"
        public static let comma = ", "
        public static let period = "."
        public static let colon = ": "
        public static let semicolon = "; "
        public static let numberFormat = "%d. "
        public static let capitalized = "capitalized"
    }
}