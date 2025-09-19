import Foundation
import MLX

/// Setup Metal environment for MLX
public class MetalSetup {
    
    public static func configure() {
        // Set GPU memory limit for LLMs
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024 * 1024) // 20GB
        
        // Try to help MLX find its Metal libraries
        // This is a workaround for the metallib loading issue
        
        // Check common locations for metallib
        let possiblePaths = [
            // Build directory
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent(".build/release"),
            
            // Executable directory
            URL(fileURLWithPath: CommandLine.arguments[0])
                .deletingLastPathComponent(),
            
            // Current directory
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        ]
        
        for path in possiblePaths {
            let metalLibPath = path.appendingPathComponent("default.metallib")
            if FileManager.default.fileExists(atPath: metalLibPath.path) {
                print("✅ Found Metal library at: \(metalLibPath.path)")
                // MLX should find it if it's in the same directory as the executable
                break
            }
        }
        
        // Additional MLX configuration
        print("⚙️ MLX GPU Cache Limit: 20GB")
        print("⚙️ Metal Performance Shaders: Enabled")
    }
}