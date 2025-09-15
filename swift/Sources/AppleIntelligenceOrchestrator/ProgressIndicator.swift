import Foundation

/// Utilities for displaying progress and status indicators
public struct ProgressIndicator {

    // MARK: - Progress Bar

    /// Creates a visual progress bar representation
    ///
    /// - Parameters:
    ///   - current: Current progress value
    ///   - total: Total value for completion
    /// - Returns: A formatted progress bar string
    public static func createProgressBar(current: Int, total: Int) -> String {
        let percentage = calculatePercentage(current: current, total: total)
        let (filled, empty) = calculateBarSegments(current: current, total: total)

        let bar = buildBar(filled: filled, empty: empty)
        return formatProgressBar(bar: bar, percentage: percentage, current: current, total: total)
    }

    // MARK: - Status Display

    /// Shows a processing status message with an indicator
    ///
    /// - Parameter message: The status message to display
    public static func showProcessingStatus(_ message: String) {
        print("\(OrchestratorConstants.Processing.statusPrefix)\(message)")
    }

    /// Runs async work with status feedback and timing
    ///
    /// - Parameters:
    ///   - message: Status message to show during work
    ///   - work: The async work to perform
    /// - Returns: The result of the async work
    public static func withStatusFeedback<T>(
        message: String,
        work: () async throws -> T
    ) async throws -> T {
        showProcessingStatus(message)

        let tracker = TimeTracker()
        let warningTimer = createWarningTimer()

        defer {
            warningTimer.invalidate()
            displayCompletionTime(elapsed: tracker.elapsed)
        }

        return try await work()
    }

    // MARK: - Private Helpers

    private static func calculatePercentage(current: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int((Double(current) / Double(total)) * 100)
    }

    private static func calculateBarSegments(current: Int, total: Int) -> (filled: Int, empty: Int) {
        guard total > 0 else { return (0, OrchestratorConstants.ProgressBar.barLength) }

        let filled = Int((Double(current) / Double(total)) * Double(OrchestratorConstants.ProgressBar.barLength))
        let empty = OrchestratorConstants.ProgressBar.barLength - filled

        return (filled, empty)
    }

    private static func buildBar(filled: Int, empty: Int) -> String {
        let filledSegment = String(repeating: OrchestratorConstants.ProgressBar.filledChar, count: filled)
        let emptySegment = String(repeating: OrchestratorConstants.ProgressBar.emptyChar, count: empty)
        return filledSegment + emptySegment
    }

    private static func formatProgressBar(bar: String, percentage: Int, current: Int, total: Int) -> String {
        return String(format: OrchestratorConstants.ProgressBar.format, bar, percentage, current, total)
    }

    private static func createWarningTimer() -> Timer {
        var warningShown = false
        return Timer.scheduledTimer(
            withTimeInterval: OrchestratorConstants.Timing.warningThreshold,
            repeats: false
        ) { _ in
            if !warningShown {
                displayDelayWarning()
                warningShown = true
            }
        }
    }

    private static func displayDelayWarning() {
        print(OrchestratorConstants.Processing.stillWaiting)
        print(OrchestratorConstants.Processing.appleIntelligenceDelay)
    }

    private static func displayCompletionTime(elapsed: TimeInterval) {
        if elapsed > OrchestratorConstants.Timing.displayThreshold {
            let formattedTime = String(format: OrchestratorConstants.Timing.elapsedFormat, elapsed)
            print("\(OrchestratorConstants.Processing.completedPrefix)\(formattedTime)\(OrchestratorConstants.Processing.secondsSuffix)")
        }
    }
}

// MARK: - Time Tracking

/// Helper struct for tracking elapsed time
private struct TimeTracker {
    private let startTime: Date

    init() {
        self.startTime = Date()
    }

    var elapsed: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
}