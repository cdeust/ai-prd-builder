import Foundation
import NaturalLanguage
import CreateML
import CoreML

/// Modern Apple Intelligence service using native frameworks
/// This replaces the brittle TextEdit automation approach
public final class AppleIntelligenceService {
    
    public enum IntelligenceCapability: Hashable {
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
    private let styleTransformer: WritingStyleTransforming
    
    public init(mode: ProcessingMode = .hybrid, styleTransformer: WritingStyleTransforming = WritingStyleTransformer()) {
        self.processingMode = mode
        self.styleTransformer = styleTransformer
        
        // Initialize NL tagger with all available tag schemes
        let schemes: [NLTagScheme] = [
            .nameType,
            .lexicalClass,
            .language,
            .script,
            .sentimentScore
        ]
        self.nlProcessor = NLTagger(tagSchemes: schemes)
        
        // Detect available capabilities via device utility
        self.capabilities = IntelligenceDeviceUtil.detectCapabilities()
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
                AppleIntelligenceConstants.Service.MetadataKeys.overallSentiment: overallSentiment,
                AppleIntelligenceConstants.Service.MetadataKeys.sentimentSegments: sentiments
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
            metadata: [AppleIntelligenceConstants.Service.MetadataKeys.entities: entities],
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
                AppleIntelligenceConstants.Service.MetadataKeys.dominantLanguage: language?.rawValue ?? AppleIntelligenceConstants.Service.MetadataKeys.unknown,
                AppleIntelligenceConstants.Service.MetadataKeys.languageHypotheses: hypotheses
            ],
            capability: .languageIdentification
        )
    }
    
    private func summarize(text: String, options: ProcessingOptions) async throws -> ProcessingResult {
        // Use NL embeddings to identify key sentences
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: AppleIntelligenceConstants.Service.TextProcessing.sentenceSeparators))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Simple extractive summarization - take first and most important sentences
        let maxSentences = options.maxSummaryLength ?? AppleIntelligenceConstants.Service.TextProcessing.defaultMaxSentences
        let summary = sentences.prefix(maxSentences).joined(separator: ". ") + AppleIntelligenceConstants.Service.TextProcessing.periodSuffix
        
        return ProcessingResult(
            processedText: summary,
            metadata: [
                AppleIntelligenceConstants.Service.MetadataKeys.originalLength: text.count,
                AppleIntelligenceConstants.Service.MetadataKeys.summaryLength: summary.count,
                AppleIntelligenceConstants.Service.MetadataKeys.compressionRatio: Double(summary.count) / Double(text.count)
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
                if phrase.count > AppleIntelligenceConstants.Service.TextProcessing.minimumPhraseLength {
                    keyPhrases.append(phrase)
                }
            }
            return true
        }
        
        // Deduplicate and format as bullet points
        let uniquePhrases = Array(Set(keyPhrases)).prefix(options.maxKeyPoints ?? AppleIntelligenceConstants.Service.TextProcessing.defaultMaxKeyPoints)
        let keyPoints = uniquePhrases.map { AppleIntelligenceConstants.Service.TextProcessing.bulletPointPrefix + $0 }.joined(separator: AppleIntelligenceConstants.Service.TextProcessing.newline)
        
        return ProcessingResult(
            processedText: keyPoints,
            metadata: [AppleIntelligenceConstants.Service.MetadataKeys.keyPhrases: uniquePhrases],
            capability: .keyPointExtraction
        )
    }
    
    private func applyWritingTools(text: String, options: ProcessingOptions) async throws -> ProcessingResult {
        // Native implementation of writing tools transformations
        var processedText = text
        
        if let style = options.writingStyle {
            processedText = styleTransformer.apply(style: style, to: text)
        }
        
        return ProcessingResult(
            processedText: processedText,
            metadata: [AppleIntelligenceConstants.Service.MetadataKeys.styleApplied: options.writingStyle?.rawValue ?? AppleIntelligenceConstants.Service.MetadataKeys.none],
            capability: .writingTools
        )
    }
    
    private func generateText(prompt: String, options: ProcessingOptions) async throws -> ProcessingResult {
        // Placeholder for text generation - will integrate with Foundation Models when available
        let generated = AppleIntelligenceConstants.Service.Placeholders.textGenerationPlaceholder
        
        return ProcessingResult(
            processedText: generated,
            metadata: [AppleIntelligenceConstants.Service.MetadataKeys.prompt: prompt],
            capability: .textGeneration
        )
    }
}
