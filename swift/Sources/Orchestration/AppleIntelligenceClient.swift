import Foundation
import AppKit
import Cocoa

/// Client for interfacing with Apple Intelligence Writing Tools
public class AppleIntelligenceClient {
    
    private let timeout: TimeInterval = AppleIntelligenceConstants.Client.Timing.defaultTimeout
    
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
        task.launchPath = AppleIntelligenceConstants.Client.ShellCommands.bashPath
        task.arguments = [AppleIntelligenceConstants.Client.ShellCommands.bashFlag, AppleIntelligenceConstants.Client.ShellCommands.checkWritingTools]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? AppleIntelligenceConstants.Common.empty
            
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
            .appendingPathExtension(AppleIntelligenceConstants.Client.FileManagement.tempFileExtension)
        
        try text.write(to: tempFile, atomically: true, encoding: .utf8)
        
        // Open the file in TextEdit
        let workspace = NSWorkspace.shared
        guard let textEditURL = workspace.urlForApplication(withBundleIdentifier: AppleIntelligenceConstants.Client.FileManagement.textEditBundleId) else {
            throw AIError.textEditNotFound
        }
        
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        
        do {
            _ = try await workspace.openApplication(at: textEditURL, configuration: config)
            
            // Wait a moment for TextEdit to launch
            try await Task.sleep(nanoseconds: AppleIntelligenceConstants.Client.Timing.launchDelay)
            
            // Open the file
            try await workspace.open([tempFile], withApplicationAt: textEditURL, configuration: config)
            
            // Wait for file to open
            try await Task.sleep(nanoseconds: AppleIntelligenceConstants.Client.Timing.launchDelay)
            
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
        let script = String(
            format: AppleIntelligenceConstants.Client.AppleScript.scriptTemplate,
            AppleIntelligenceConstants.Client.Timing.scriptDelay,
            command.rawValue,
            AppleIntelligenceConstants.Client.Timing.scriptDelay,
            AppleIntelligenceConstants.Client.Timing.processingDelay,
            AppleIntelligenceConstants.Client.Timing.scriptDelay,
            AppleIntelligenceConstants.Client.Timing.scriptDelay
        )
        
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            throw AIError.automationFailed(AppleIntelligenceConstants.Client.ErrorMessages.failedToCreateScript)
        }
        
        let result = appleScript.executeAndReturnError(&error)
        
        if let error = error {
            throw AIError.automationFailed(error.description)
        }
        
        return result.stringValue ?? AppleIntelligenceConstants.Common.empty
    }
    
    private func closeTextEdit() {
        let script = AppleIntelligenceConstants.Client.AppleScript.closeTextEditScript
        
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
        <task>Generate Product Requirements Document</task>

        <input>
        Feature: \(feature)
        Priority: \(priority)
        Context: \(context)
        Requirements: \(requirements.joined(separator: AppleIntelligenceConstants.Client.PRDGeneration.requirementsSeparator))
        </input>

        <instruction>
        Plan and create a comprehensive Product Requirements Document (PRD) for the above feature.

        Include the following sections:
        - Executive Summary
        - Problem Statement
        - Success Metrics
        - User Stories
        - Functional Requirements
        - Non-Functional Requirements
        - Technical Considerations
        - Acceptance Criteria
        - Risks and Mitigation

        Think strategically about the feature implementation and consider all stakeholder perspectives.
        </instruction>
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
