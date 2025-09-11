import Foundation
import AppKit
import Cocoa

/// Client for interfacing with Apple Intelligence Writing Tools
public class AppleIntelligenceClient {
    
    public enum WritingToolsCommand: String {
        case rewrite = "Rewrite"
        case makeFriendly = "Make Friendly"
        case makeProfessional = "Make Professional"
        case makeConcise = "Make Concise"
        case summarize = "Summarize"
        case keyPoints = "Create Key Points"
        case list = "Make List"
        case table = "Make Table"
        case proofread = "Proofread"
    }
    
    public enum AIError: Error {
        case writingToolsNotAvailable
        case textEditNotFound
        case automationFailed(String)
        case timeout
    }
    
    private let timeout: TimeInterval = 30.0
    
    public init() {}
    
    /// Check if Apple Intelligence is available on this system
    public func isAvailable() -> Bool {
        // Check macOS version (15.1+)
        if #available(macOS 15.1, *) {
            // Check if Writing Tools is enabled
            return checkWritingToolsAvailability()
        }
        return false
    }
    
    private func checkWritingToolsAvailability() -> Bool {
        // Check if Writing Tools process exists
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "ps aux | grep -i 'writing.*tools' | grep -v grep"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return !output.isEmpty
        } catch {
            return false
        }
    }
    
    /// Apply a Writing Tools command to text using TextEdit automation
    public func applyWritingTools(
        text: String,
        command: WritingToolsCommand
    ) async throws -> String {
        
        guard isAvailable() else {
            throw AIError.writingToolsNotAvailable
        }
        
        // Create a temporary file with the text
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("txt")
        
        try text.write(to: tempFile, atomically: true, encoding: .utf8)
        
        // Open the file in TextEdit
        let workspace = NSWorkspace.shared
        guard let textEditURL = workspace.urlForApplication(withBundleIdentifier: "com.apple.TextEdit") else {
            throw AIError.textEditNotFound
        }
        
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        
        do {
            _ = try await workspace.openApplication(at: textEditURL, configuration: config)
            
            // Wait a moment for TextEdit to launch
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Open the file
            try await workspace.open([tempFile], withApplicationAt: textEditURL, configuration: config)
            
            // Wait for file to open
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Apply Writing Tools using AppleScript
            let result = try await applyWritingToolsViaAppleScript(command: command)
            
            // Close TextEdit
            closeTextEdit()
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempFile)
            
            return result
            
        } catch {
            // Clean up on error
            try? FileManager.default.removeItem(at: tempFile)
            throw AIError.automationFailed(error.localizedDescription)
        }
    }
    
    private func applyWritingToolsViaAppleScript(command: WritingToolsCommand) async throws -> String {
        let script = """
        tell application "System Events"
            tell process "TextEdit"
                set frontmost to true
                
                -- Select all text
                keystroke "a" using command down
                delay 0.5
                
                -- Open Writing Tools (Cmd+Shift+W typically)
                keystroke "w" using {command down, shift down}
                delay 1
                
                -- Navigate to the command
                keystroke "\(command.rawValue)"
                delay 0.5
                keystroke return
                
                -- Wait for processing
                delay 3
                
                -- Copy the result
                keystroke "a" using command down
                delay 0.5
                keystroke "c" using command down
                delay 0.5
                
                -- Get from clipboard
                set resultText to the clipboard as string
            end tell
        end tell
        
        return resultText
        """
        
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            throw AIError.automationFailed("Failed to create AppleScript")
        }
        
        let result = appleScript.executeAndReturnError(&error)
        
        if let error = error {
            throw AIError.automationFailed(error.description)
        }
        
        return result.stringValue ?? ""
    }
    
    private func closeTextEdit() {
        let script = """
        tell application "TextEdit"
            quit saving no
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
    }
    
    /// Generate a PRD using Apple Intelligence
    public func generatePRD(
        feature: String,
        context: String,
        priority: String,
        requirements: [String]
    ) async throws -> String {
        
        let prompt = """
        Create a comprehensive Product Requirements Document (PRD) for:
        
        Feature: \(feature)
        Priority: \(priority)
        Context: \(context)
        Requirements: \(requirements.joined(separator: ", "))
        
        Include:
        1. Executive Summary
        2. Problem Statement
        3. Success Metrics
        4. User Stories
        5. Functional Requirements
        6. Non-Functional Requirements
        7. Technical Considerations
        8. Acceptance Criteria
        9. Timeline
        10. Risks and Mitigation
        """
        
        // First, ask to rewrite as a PRD
        let rewritten = try await applyWritingTools(
            text: prompt,
            command: .rewrite
        )
        
        // Then make it professional
        let professional = try await applyWritingTools(
            text: rewritten,
            command: .makeProfessional
        )
        
        return professional
    }
}