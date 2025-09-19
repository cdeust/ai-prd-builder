import Foundation

public struct ProcessingOptions {
    public var writingStyle: WritingStyle?
    public var maxSummaryLength: Int?
    public var maxKeyPoints: Int?
    public var language: String?
    
    public enum WritingStyle: String {
        case professional
        case friendly
        case concise
        case detailed
    }
    
    public init(
        writingStyle: WritingStyle? = nil,
        maxSummaryLength: Int? = nil,
        maxKeyPoints: Int? = nil,
        language: String? = nil
    ) {
        self.writingStyle = writingStyle
        self.maxSummaryLength = maxSummaryLength
        self.maxKeyPoints = maxKeyPoints
        self.language = language
    }
}
