import Foundation

/// Constants for data processing, file handling, and technical details
public enum PRDDataConstants {

    // MARK: - File Extensions
    public enum FileExtensions {
        public static let allImageExtensions = ["png", "jpg", "jpeg", "gif", "svg", "pdf", "sketch", "fig", "xd", "ai", "psd"]
        public static let webImageExtensions = ["png", "jpg", "jpeg", "gif", "svg", "pdf"]
        public static let designToolExtensions = ["sketch", "fig", "xd", "ai", "psd"]
    }

    // MARK: - URL & Path Prefixes
    public enum Prefixes {
        // URL prefixes
        public static let dataImage = "data:image/"
        public static let http = "http://"
        public static let https = "https://"
        public static let file = "file://"

        // Path prefixes
        public static let root = "/"
        public static let current = "./"
        public static let parent = "../"
        public static let home = "~"
        public static let varFolders = "/var/folders/"
        public static let tmp = "/tmp/"
        public static let hash = "#"
    }

    // MARK: - Data Separators
    public enum Separators {
        public static let comma = ","
        public static let semicolon = ";"
        public static let colon = ":"
        public static let dot = "."
        public static let underscore = "_"
        public static let dash = "-"
        public static let space = " "
        public static let newline = "\n"
        public static let doubleNewline = "\n\n"
        public static let sectionSeparator = "\n\n---\n\n"
        public static let empty = ""
    }

    // MARK: - MIME Types & Data
    public enum MimeTypes {
        public static let dataPrefix = "data:"
        public static let imagePrefix = "image/"
        public static let xmlSuffix = "+xml"
        public static let base64Suffix = ";base64,"
    }

    // MARK: - Default Values
    public enum Defaults {
        public static let prdGeneratorName = "PRDGenerator"
        public static let prdVersion = "4.0"
        public static let totalPasses = 8
        public static let generationApproach = "Multi-pass generation"
        public static let defaultConfidence = 75
        public static let unknown = "Unknown"
        public static let tbd = "TBD"
        public static let xctest = "XCTest"
        public static let defaultMockupName = "mockup.png"
        public static let mockupPrefix = "mockup_"
    }

    // MARK: - Metadata Keys
    public enum MetadataKeys {
        public static let generator = "generator"
        public static let version = "version"
        public static let timestamp = "timestamp"
        public static let passes = "passes"
        public static let approach = "approach"
    }

    // MARK: - JSON Keys
    public enum JSONKeys {
        public static let confidence = "confidence"
        public static let assumptions = "assumptions"
        public static let gaps = "gaps"
        public static let recommendations = "recommendations"
        public static let clarifications = "clarifications_needed"
        public static let features = "features"
        public static let userFlows = "userFlows"
        public static let uiComponents = "uiComponents"
        public static let businessContext = "businessContext"
        public static let enrichedDescription = "enrichedDescription"
    }

    // MARK: - Regex Patterns
    public enum RegexPatterns {
        public static let markdownImage = #"!\[([^\]]*)\]\(([^)]+)\)"#
        public static let htmlImage = #"<img[^>]+src=["']([^"']+)["'][^>]*>"#
        public static let htmlImageTag = #"<img[^>]+>"#
        public static let codeBlock = "```"
        public static let jsonCodeBlockStart = "```json\n"
        public static let jsonCodeBlockEnd = "\n```"
    }

    // MARK: - Image Hosts
    public enum ImageHosts {
        public static let hosts = ["imgur", "cloudinary", "s3", "githubusercontent", "dropbox", "figma"]
    }

    // MARK: - Confidence Thresholds
    public enum Confidence {
        public static let minimum = 20
        public static let low = 40
        public static let medium = 60
        public static let high = 80
        public static let veryHigh = 90
        public static let maximum = 100
        public static let defaultValue = 75
    }

    // MARK: - Limits
    public enum Limits {
        public static let maxClarificationQuestions = 10
        public static let maxAssumptions = 20
        public static let maxIterations = 3
        public static let maxSectionLength = 5000
        public static let maxPromptLength = 8000
    }
}