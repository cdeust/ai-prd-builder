import Foundation

/// Low-level errors related to Apple Intelligence client operations
/// (availability checks, app automation, scripting, timeouts)
public enum AIError: Error {
    case writingToolsNotAvailable
    case textEditNotFound
    case automationFailed(String)
    case timeout
}
