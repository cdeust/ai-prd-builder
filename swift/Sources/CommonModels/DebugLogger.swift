import Foundation

/// Utility for conditional debug logging
public enum DebugLogger {
    /// Optional callback for routing messages through interaction handler
    public static var messageCallback: ((String) -> Void)?

    /// Check if DEBUG environment variable is set
    public static var isDebugEnabled: Bool {
        return ProcessInfo.processInfo.environment["DEBUG"] != nil
    }

    /// Print debug message only if DEBUG is enabled
    public static func debug(_ message: String) {
        if isDebugEnabled {
            if let callback = messageCallback {
                callback("[DEBUG] \(message)")
            } else {
                print("[DEBUG] \(message)")
            }
        }
    }

    /// Print debug message with custom prefix only if DEBUG is enabled
    public static func debug(_ message: String, prefix: String) {
        if isDebugEnabled {
            if let callback = messageCallback {
                callback("[\(prefix)] \(message)")
            } else {
                print("[\(prefix)] \(message)")
            }
        }
    }

    /// Print AI response with provider info
    public static func aiResponse(_ response: String, provider: String) {
        if isDebugEnabled {
            if let callback = messageCallback {
                callback("\n[Provider: \(provider)]\n\(response)\n")
            } else {
                print("\n[Provider: \(provider)]\n\(response)\n")
            }
        }
    }

    /// Always print important messages (errors, completion, etc.)
    public static func always(_ message: String) {
        if let callback = messageCallback {
            callback(message)
        } else {
            print(message)
        }
    }
}