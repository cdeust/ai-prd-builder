import Foundation

/// Protocol for handling user interactions during PRD generation
public protocol UserInteractionHandler {
    /// Ask the user a question and get their response
    func askQuestion(_ question: String) async -> String

    /// Ask the user to select from multiple options
    func askMultipleChoice(_ question: String, options: [String]) async -> String

    /// Ask the user a yes/no question
    func askYesNo(_ question: String) async -> Bool

    /// Show information to the user
    func showInfo(_ message: String)
}

/// Default implementation that reads from console
public class ConsoleInteractionHandler: UserInteractionHandler {

    public init() {}

    public func askQuestion(_ question: String) async -> String {
        print("\n❓ \(question)")
        print("   > ", terminator: "")
        return readLine() ?? ""
    }

    public func askMultipleChoice(_ question: String, options: [String]) async -> String {
        print("\n❓ \(question)")
        for (index, option) in options.enumerated() {
            print("   \(index + 1). \(option)")
        }
        print("   > ", terminator: "")

        if let input = readLine(),
           let choice = Int(input),
           choice > 0 && choice <= options.count {
            return options[choice - 1]
        }

        // Default to first option if invalid input
        return options.first ?? ""
    }

    public func askYesNo(_ question: String) async -> Bool {
        print("\n❓ \(question) (y/n)")
        print("   > ", terminator: "")
        let response = readLine()?.lowercased() ?? "n"
        return response == "y" || response == "yes"
    }

    public func showInfo(_ message: String) {
        print("\nℹ️ \(message)")
    }
}

/// Mock implementation for testing
public class MockInteractionHandler: UserInteractionHandler {
    private var responses: [String]
    private var responseIndex = 0

    public init(responses: [String] = []) {
        self.responses = responses
    }

    public func askQuestion(_ question: String) async -> String {
        defer { responseIndex += 1 }
        return responseIndex < responses.count ? responses[responseIndex] : ""
    }

    public func askMultipleChoice(_ question: String, options: [String]) async -> String {
        defer { responseIndex += 1 }
        return responseIndex < responses.count ? responses[responseIndex] : options.first ?? ""
    }

    public func askYesNo(_ question: String) async -> Bool {
        defer { responseIndex += 1 }
        let response = responseIndex < responses.count ? responses[responseIndex] : "n"
        return response == "y" || response == "yes"
    }

    public func showInfo(_ message: String) {
        // Silent in mock
    }
}