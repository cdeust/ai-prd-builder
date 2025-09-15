import Foundation

/// Configures Metal environment for Apple Intelligence via MLX.
public struct MetalSetup {

    /// Configures Metal environment variables for Apple Intelligence.
    ///
    /// Sets up necessary Metal debugging and performance flags
    /// to ensure optimal Apple Intelligence operation via MLX/Metal.
    public static func configure() {
        #if os(macOS)
        configureDebugMode()
        configurePerformanceMode()
        #endif
    }

    // MARK: - Private Configuration Methods

    #if os(macOS)
    private static func configureDebugMode() {
        #if DEBUG
        // Enable Metal API validation in debug builds
        setenv(OrchestratorConstants.Environment.metalDeviceWrapper, "1", 1)
        #endif
    }

    private static func configurePerformanceMode() {
        // Disable Metal API validation in release for performance
        setenv(OrchestratorConstants.Environment.metalDebugError, "0", 1)
    }
    #endif
}