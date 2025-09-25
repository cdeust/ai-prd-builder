import Foundation

/// Detects whether a task is incremental (adding to existing system) or greenfield (new project)
public final class TaskContextDetector {

    public enum TaskType: CustomStringConvertible {
        case incremental  // Adding feature to existing system
        case greenfield   // New project from scratch
        case bugFix       // Fixing existing functionality
        case refactor     // Improving existing code
        case configuration // Config/setup changes

        public var description: String {
            switch self {
            case .incremental: return PRDDisplayConstants.TaskTypeDisplay.incremental
            case .greenfield: return PRDDisplayConstants.TaskTypeDisplay.greenfield
            case .bugFix: return PRDDisplayConstants.TaskTypeDisplay.bugFix
            case .refactor: return PRDDisplayConstants.TaskTypeDisplay.refactor
            case .configuration: return PRDDisplayConstants.TaskTypeDisplay.configuration
            }
        }
    }

    /// Keywords that indicate a greenfield project
    private static let greenfieldIndicators = PRDAnalysisConstants.TaskTypeKeywords.greenfield

    /// Keywords that indicate incremental work
    private static let incrementalIndicators = PRDAnalysisConstants.TaskTypeKeywords.incremental

    /// Keywords that indicate bug fixes
    private static let bugFixIndicators = PRDAnalysisConstants.TaskTypeKeywords.bugFix

    /// Keywords that indicate refactoring
    private static let refactorIndicators = PRDAnalysisConstants.TaskTypeKeywords.refactor

    /// Keywords that indicate configuration
    private static let configIndicators = PRDAnalysisConstants.TaskTypeKeywords.configuration

    /// Detect the type of task from the description
    public func detectTaskType(from description: String) -> TaskType {
        let lowercased = description.lowercased()

        // Check for bug fixes first (highest priority)
        for indicator in Self.bugFixIndicators {
            if lowercased.contains(indicator) {
                return .bugFix
            }
        }

        // Check for refactoring
        for indicator in Self.refactorIndicators {
            if lowercased.contains(indicator) {
                return .refactor
            }
        }

        // Check for configuration
        for indicator in Self.configIndicators {
            if lowercased.contains(indicator) {
                return .configuration
            }
        }

        // Check for greenfield
        var greenfieldScore = 0
        for indicator in Self.greenfieldIndicators {
            if lowercased.contains(indicator) {
                greenfieldScore += 1
            }
        }

        // Check for incremental
        var incrementalScore = 0
        for indicator in Self.incrementalIndicators {
            if lowercased.contains(indicator) {
                incrementalScore += 1
            }
        }

        // If we have strong greenfield indicators, it's greenfield
        if greenfieldScore >= 2 || (greenfieldScore > 0 && incrementalScore == 0) {
            return .greenfield
        }

        // Default to incremental (most common case)
        return .incremental
    }

    /// Get context assumptions based on task type
    public func getContextAssumptions(for taskType: TaskType) -> String {
        switch taskType {
        case .incremental:
            return PRDContextConstants.ContextAssumptions.incremental

        case .greenfield:
            return PRDContextConstants.ContextAssumptions.greenfield

        case .bugFix:
            return PRDContextConstants.ContextAssumptions.bugFix

        case .refactor:
            return PRDContextConstants.ContextAssumptions.refactor

        case .configuration:
            return PRDContextConstants.ContextAssumptions.configuration
        }
    }

    /// Adjust prompt based on task type
    public func adjustPromptForContext(_ basePrompt: String, taskType: TaskType) -> String {
        let contextPrefix: String

        switch taskType {
        case .incremental:
            contextPrefix = PRDContextConstants.ContextPrefixes.incremental
        case .greenfield:
            contextPrefix = PRDContextConstants.ContextPrefixes.greenfield
        case .bugFix:
            contextPrefix = PRDContextConstants.ContextPrefixes.bugFix
        case .refactor:
            contextPrefix = PRDContextConstants.ContextPrefixes.refactor
        case .configuration:
            contextPrefix = PRDContextConstants.ContextPrefixes.configuration
        }

        return contextPrefix + basePrompt
    }
}