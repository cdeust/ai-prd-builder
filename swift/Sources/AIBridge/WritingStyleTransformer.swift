import Foundation

public protocol WritingStyleTransforming {
    func apply(style: ProcessingOptions.WritingStyle, to text: String) -> String
    func applyProfessionalTone(to text: String) -> String
    func applyFriendlyTone(to text: String) -> String
    func applyConciseStyle(to text: String) -> String
}

public final class WritingStyleTransformer: WritingStyleTransforming {
    public init() {}
    
    public func apply(style: ProcessingOptions.WritingStyle, to text: String) -> String {
        switch style {
        case .professional:
            return applyProfessionalTone(to: text)
        case .friendly:
            return applyFriendlyTone(to: text)
        case .concise:
            return applyConciseStyle(to: text)
        case .detailed:
            // Placeholder: keep text unchanged or extend with detailed logic later
            return text
        }
    }
    
    public func applyProfessionalTone(to text: String) -> String {
        var result = text
        let replacements = [
            "hey": "Hello",
            "Hi": "Greetings",
            "thanks": "Thank you",
            "gonna": "going to",
            "wanna": "want to",
            "kinda": "kind of",
            "sorta": "sort of"
        ]
        for (casual, professional) in replacements {
            result = result.replacingOccurrences(of: casual, with: professional, options: .caseInsensitive)
        }
        return result
    }
    
    public func applyFriendlyTone(to text: String) -> String {
        var result = text
        if !result.contains("!") && !result.contains("?") {
            result = result.replacingOccurrences(of: ".", with: "!")
        }
        return result
    }
    
    public func applyConciseStyle(to text: String) -> String {
        let wordsToRemove = ["very", "really", "actually", "basically", "just", "simply"]
        var words = text.components(separatedBy: .whitespaces)
        words = words.filter { word in
            !wordsToRemove.contains(word.lowercased())
        }
        return words.joined(separator: " ")
    }
}
