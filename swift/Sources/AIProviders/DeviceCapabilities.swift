import Foundation

public struct DeviceCapabilities {
    public let hasAppleSilicon: Bool
    public let hasFoundationModels: Bool
    public let supportsPCC: Bool
    public let osVersion: String
    public let availableMemoryGB: Int
    
    public static func probe() -> DeviceCapabilities {
        #if os(macOS)
        var size = 0
        sysctlbyname("hw.optional.arm64", nil, &size, nil, 0)
        let hasAppleSilicon = size > 0
        
        // Check for Foundation Models availability
        var hasFoundationModels = false
        if #available(macOS 16.0, iOS 26.0, *) {
            // FoundationModels framework is available
            hasFoundationModels = hasAppleSilicon
        }
        
        let supportsPCC = hasFoundationModels && hasAppleSilicon
        
        let processInfo = ProcessInfo.processInfo
        let osVersion = "\(processInfo.operatingSystemVersion.majorVersion).\(processInfo.operatingSystemVersion.minorVersion)"
        let availableMemory = Int(processInfo.physicalMemory / (1024 * 1024 * 1024))
        
        return DeviceCapabilities(
            hasAppleSilicon: hasAppleSilicon,
            hasFoundationModels: hasFoundationModels,
            supportsPCC: supportsPCC,
            osVersion: osVersion,
            availableMemoryGB: availableMemory
        )
        #else
        return DeviceCapabilities(
            hasAppleSilicon: false,
            hasFoundationModels: false,
            supportsPCC: false,
            osVersion: "iOS",
            availableMemoryGB: 4
        )
        #endif
    }
}
