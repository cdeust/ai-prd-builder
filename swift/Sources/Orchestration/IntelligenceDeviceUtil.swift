import Foundation

public enum IntelligenceDeviceUtil {
    public static func detectCapabilities() -> Set<AppleIntelligenceService.IntelligenceCapability> {
        var caps: Set<AppleIntelligenceService.IntelligenceCapability> = []
        
        // Check OS version for various capabilities
        if #available(macOS 15.0, *) {
            caps.insert(.writingTools)
            caps.insert(.summarization)
            caps.insert(.keyPointExtraction)
        }
        
        if #available(macOS 14.0, *) {
            caps.insert(.sentimentAnalysis)
            caps.insert(.entityRecognition)
            caps.insert(.languageIdentification)
        }
        
        if #available(macOS 13.0, *) {
            caps.insert(.textGeneration)
        }
        
        return caps
    }
}
