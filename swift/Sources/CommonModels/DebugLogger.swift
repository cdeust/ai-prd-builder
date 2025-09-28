import Foundation

/// Utility for conditional debug logging
public enum DebugLogger {
    /// Optional callback for routing messages through interaction handler
    public static var messageCallback: ((String) -> Void)?

    /// Track if callback failed to avoid repeated fallback warnings
    private static var callbackFailed = false

    /// Check if DEBUG environment variable is set
    public static var isDebugEnabled: Bool {
        return ProcessInfo.processInfo.environment["DEBUG"] != nil
    }

    /// Safely invoke callback with fallback to print
    private static func safeOutput(_ message: String) {
        guard let callback = messageCallback else {
            print(message)
            return
        }

        // Attempt callback invocation
        callback(message)
    }

    /// Print debug message only if DEBUG is enabled
    public static func debug(_ message: String) {
        if isDebugEnabled {
            safeOutput("[DEBUG] \(message)")
        }
    }

    /// Print debug message with custom prefix only if DEBUG is enabled
    public static func debug(_ message: String, prefix: String) {
        if isDebugEnabled {
            safeOutput("[\(prefix)] \(message)")
        }
    }

    /// Print AI response with provider info
    public static func aiResponse(_ response: String, provider: String) {
        if isDebugEnabled {
            safeOutput("\n[Provider: \(provider)]\n\(response)\n")
        }
    }

    /// Always print important messages (errors, completion, etc.)
    public static func always(_ message: String) {
        safeOutput(message)
    }

    /// Reset callback failure state (for testing)
    public static func resetCallbackState() {
        callbackFailed = false
    }
}