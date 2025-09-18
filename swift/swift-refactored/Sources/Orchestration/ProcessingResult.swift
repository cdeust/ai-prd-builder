import Foundation

public struct ProcessingResult {
    public let processedText: String
    public let metadata: [String: Any]
    public let capability: AppleIntelligenceService.IntelligenceCapability
    public let processingTime: TimeInterval?
    
    public init(
        processedText: String,
        metadata: [String: Any] = [:],
        capability: AppleIntelligenceService.IntelligenceCapability,
        processingTime: TimeInterval? = nil
    ) {
        self.processedText = processedText
        self.metadata = metadata
        self.capability = capability
        self.processingTime = processingTime
    }
}
