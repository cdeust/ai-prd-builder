import Foundation
import NaturalLanguage
import CreateML
import CoreML

/// Modern Apple Intelligence service using native frameworks
/// This replaces the brittle TextEdit automation approach
public final class AppleIntelligenceService {
    
    public enum IntelligenceCapability {
        case writingTools
        case summarization
        case keyPointExtraction
        case sentimentAnalysis
        case entityRecognition
        case languageIdentification
        case textGeneration
    }
    
    public enum ProcessingMode {
        case onDevice       // Fully on-device processing
        case pcc           // Private Cloud Compute when needed
        case hybrid        // Automatic selection based on task
    }
    
    private let nlProcessor: NLTagger
    private let processingMode: ProcessingMode
    private var capabilities: Set<IntelligenceCapability> = []
    
    public init(mode: ProcessingMode = .hybrid) {
        self.processingMode = mode
        
        // Initialize NL tagger with all available tag schemes
        let schemes: [NLTagScheme] = [
            .nameType,
            .lexicalClass,
            .language,
            .script,
            .sentimentScore
        ]
        self.nlProcessor = NLTagger(tagSchemes: schemes)
        
        // Detect available capabilities
        self.capabilities = Self.detectCapabilities()
    }
    
    private static func detectCapabilities() -> Set<IntelligenceCapability> {
        var caps: Set<IntelligenceCapability> = []
        
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
    
    public func isCapabilityAvailable(_ capability: IntelligenceCapability) -> Bool {
        return capabilities.contains(capability)
    }
    
    /// Process text with specified intelligence capability
    public func process(
        text: String,
        capability: IntelligenceCapability,
        options: ProcessingOptions = ProcessingOptions()
    ) async throws -> ProcessingResult {
        
        guard isCapabilityAvailable(capability) else {
            throw IntelligenceError.capabilityNotAvailable(capability)
        }
        
        switch capability {
        case .sentimentAnalysis:
            return try await analyzeSentiment(text: text, options: options)
            
        case .entityRecognition:
            return try await recognizeEntities(text: text, options: options)
            
        case .languageIdentification:
            return try await identifyLanguage(text: text)
            
        case .summarization:
            return try await summarize(text: text, options: options)
            
        case .keyPointExtraction:
            return try await extractKeyPoints(text: text, options: options)
            
        case .writingTools:
            return try await applyWritingTools(text: text, options: options)
            
        case .textGeneration:
            return try await generateText(prompt: text, options: options)
        }
    }
    
    // MARK: - Private Processing Methods
    
    private func analyzeSentiment(text: String, options: ProcessingOptions) async throws -> ProcessingResult {
        nlProcessor.string = text
        
        var sentiments: [(String, Double)] = []
        let range = text.startIndex..<text.endIndex
        
        nlProcessor.enumerateTags(
            in: range,
            unit: .sentence,
            scheme: .sentimentScore,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, tokenRange in
            if let tag = tag {
                let substring = String(text[tokenRange])
                let score = Double(tag.rawValue) ?? 0.0
                sentiments.append((substring, score))
            }
            return true
        }
        
        let overallSentiment = sentiments.isEmpty ? 0.0 : 
            sentiments.map { $0.1 }.reduce(0.0, +) / Double(sentiments.count)
        
        return ProcessingResult(
            processedText: text,
            metadata: [
                "overall_sentiment": overallSentiment,
                "sentiment_segments": sentiments
            ],
            capability: .sentimentAnalysis
        )
    }
    
    private func recognizeEntities(text: String, options: ProcessingOptions) async throws -> ProcessingResult {
        nlProcessor.string = text
        
        var entities: [(String, NLTag)] = []
        let range = text.startIndex..<text.endIndex
        
        nlProcessor.enumerateTags(
            in: range,
            unit: .word,
            scheme: .nameType,
            options: [.omitWhitespace, .omitPunctuation, .joinNames]
        ) { tag, tokenRange in
            if let tag = tag {
                let entity = String(text[tokenRange])
                entities.append((entity, tag))
            }
            return true
        }
        
        return ProcessingResult(
            processedText: text,
            metadata: ["entities": entities],
            capability: .entityRecognition
        )
    }
    
    private func identifyLanguage(text: String) async throws -> ProcessingResult {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        let language = recognizer.dominantLanguage
        let hypotheses = recognizer.languageHypotheses(withMaximum: 3)
        
        return ProcessingResult(
            processedText: text,
            metadata: [
                "dominant_language": language?.rawValue ?? "unknown",
                "language_hypotheses": hypotheses
            ],
            capability: .languageIdentification
        )
    }
    
    private func summarize(text: String, options: ProcessingOptions) async throws -> ProcessingResult {
        // Use NL embeddings to identify key sentences
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Simple extractive summarization - take first and most important sentences
        let maxSentences = options.maxSummaryLength ?? 3
        let summary = sentences.prefix(maxSentences).joined(separator: ". ") + "."
        
        return ProcessingResult(
            processedText: summary,
            metadata: [
                "original_length": text.count,
                "summary_length": summary.count,
                "compression_ratio": Double(summary.count) / Double(text.count)
            ],
            capability: .summarization
        )
    }
    
    private func extractKeyPoints(text: String, options: ProcessingOptions) async throws -> ProcessingResult {
        // Extract key noun phrases using NLTagger
        nlProcessor.string = text
        
        var keyPhrases: [String] = []
        let range = text.startIndex..<text.endIndex
        
        nlProcessor.enumerateTags(
            in: range,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, tokenRange in
            if tag == .noun || tag == .verb {
                let phrase = String(text[tokenRange])
                if phrase.count > 3 { // Filter out very short words
                    keyPhrases.append(phrase)
                }
            }
            return true
        }
        
        // Deduplicate and format as bullet points
        let uniquePhrases = Array(Set(keyPhrases)).prefix(options.maxKeyPoints ?? 5)
        let keyPoints = uniquePhrases.map { "• \($0)" }.joined(separator: "\n")
        
        return ProcessingResult(
            processedText: keyPoints,
            metadata: ["key_phrases": uniquePhrases],
            capability: .keyPointExtraction
        )
    }
    
    private func applyWritingTools(text: String, options: ProcessingOptions) async throws -> ProcessingResult {
        // Native implementation of writing tools transformations
        var processedText = text
        
        switch options.writingStyle {
        case .professional:
            processedText = makeTextProfessional(text)
        case .friendly:
            processedText = makeTextFriendly(text)
        case .concise:
            processedText = makeTextConcise(text)
        default:
            break
        }
        
        return ProcessingResult(
            processedText: processedText,
            metadata: ["style_applied": options.writingStyle?.rawValue ?? "none"],
            capability: .writingTools
        )
    }
    
    private func generateText(prompt: String, options: ProcessingOptions) async throws -> ProcessingResult {
        // Placeholder for text generation - will integrate with Foundation Models when available
        let generated = "[Text generation will be available with Foundation Models API]"
        
        return ProcessingResult(
            processedText: generated,
            metadata: ["prompt": prompt],
            capability: .textGeneration
        )
    }
    
    // MARK: - Text Style Transformations
    
    private func makeTextProfessional(_ text: String) -> String {
        // Simple rule-based transformation for now
        var result = text
        
        // Replace casual phrases
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
    
    private func makeTextFriendly(_ text: String) -> String {
        // Add friendly tone
        var result = text
        
        // Simple transformations
        if !result.contains("!") && !result.contains("?") {
            result = result.replacingOccurrences(of: ".", with: "!")
        }
        
        return result
    }
    
    private func makeTextConcise(_ text: String) -> String {
        // Remove redundant words and phrases
        let wordsToRemove = ["very", "really", "actually", "basically", "just", "simply"]
        
        var words = text.components(separatedBy: .whitespaces)
        words = words.filter { word in
            !wordsToRemove.contains(word.lowercased())
        }
        
        return words.joined(separator: " ")
    }
}

// MARK: - Supporting Types

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

public enum IntelligenceError: Error, LocalizedError {
    case capabilityNotAvailable(AppleIntelligenceService.IntelligenceCapability)
    case processingFailed(String)
    case invalidInput
    
    public var errorDescription: String? {
        switch self {
        case .capabilityNotAvailable(let capability):
            return "Capability not available: \(capability)"
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        case .invalidInput:
            return "Invalid input provided"
        }
    }
}