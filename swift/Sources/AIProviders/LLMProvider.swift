import Foundation

// MARK: - Core Types matching Apple's pattern

public struct LLMRequest {
    public var system: String?
    public var messages: [(role: String, content: String)]
    public var jsonSchema: String?    // optional schema for JSON responses
    public var temperature: Double = 0.4
    public var stream: Bool = false
    
    public init(
        system: String? = nil,
        messages: [(role: String, content: String)] = [],
        jsonSchema: String? = nil,
        temperature: Double = 0.4,
        stream: Bool = false
    ) {
        self.system = system
        self.messages = messages
        self.jsonSchema = jsonSchema
        self.temperature = temperature
        self.stream = stream
    }
}

public struct LLMResponse {
    public var text: String
    public var raw: Data?
    public var provider: String?
    public var tokensUsed: Int?
    public var latencyMs: Int?
    
    public init(text: String, raw: Data? = nil, provider: String? = nil, tokensUsed: Int? = nil, latencyMs: Int? = nil) {
        self.text = text
        self.raw = raw
        self.provider = provider
        self.tokensUsed = tokensUsed
        self.latencyMs = latencyMs
    }
}

public protocol LLMProvider {
    var name: String { get }
    func generate(_ req: LLMRequest) async throws -> LLMResponse
    func isAvailable() -> Bool
}

// MARK: - Device Capability Detection

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