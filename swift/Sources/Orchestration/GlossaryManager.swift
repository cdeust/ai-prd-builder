import Foundation

/// Manages glossary loading, acronym policies, and domain-specific terminology
/// Works with SessionManagement to provide glossary functionality
public class GlossaryManager {

    // MARK: - Properties

    private let sessionManager: SessionManagement
    private var defaultGlossary: Glossary?

    // MARK: - Initialization

    public init(sessionManager: SessionManagement) {
        self.sessionManager = sessionManager

        // Load default glossary asynchronously
        Task {
            await loadDefaultGlossary()
        }
    }

    // MARK: - Glossary Loading

    /// Loads the default glossary from YAML configuration
    public func loadDefaultGlossary() async {
        do {
            var config: GlossaryConfiguration? = nil

            // Try to load from the source directory first (for development)
            let fileManager = FileManager.default

            // Try multiple possible relative paths
            let possiblePaths = [
                // Relative path from package root
                "Sources/AIBridge/Glossary.yaml",
                // Relative path with current directory
                "\(fileManager.currentDirectoryPath)/Sources/AIBridge/Glossary.yaml",
                // Check if we're in a subdirectory and need to go up
                "../Sources/AIBridge/Glossary.yaml",
                "../../Sources/AIBridge/Glossary.yaml"
            ]

            for path in possiblePaths {
                if fileManager.fileExists(atPath: path) {
                    #if canImport(Yams)
                    let loader = FileYAMLGlossaryLoader(filePath: path)
                    config = try loader.load()
                    break
                    #endif
                }
            }

            if config == nil {
                // Fallback to bundle loader for production
                #if canImport(Yams)
                let loader = BundleYAMLGlossaryLoader()
                #else
                let loader = BundleGlossaryLoader()
                #endif
                config = try loader.load()
            }

            if let config = config {
                let glossary = Glossary(
                    domain: OrchestratorConstants.Defaults.domain,
                    entries: config.acronyms.map { Glossary.Entry(acronym: $0.key, definition: $0.value) }
                )
                defaultGlossary = glossary

                // Set it for the current session if it doesn't have one
                if sessionManager.glossaryForCurrentSession().entries.isEmpty {
                    sessionManager.setGlossaryForCurrentSession(glossary)
                }
            } else {
                // Use empty glossary if nothing loaded
                defaultGlossary = Glossary(domain: OrchestratorConstants.Defaults.domain, entries: [])
            }
        } catch {
            // Silently fail and use empty glossary to avoid noise
            defaultGlossary = Glossary(domain: OrchestratorConstants.Defaults.domain, entries: [])
        }
    }

    /// Ensures glossary is loaded and available
    private func ensureGlossaryLoaded() async {
        if defaultGlossary == nil {
            await loadDefaultGlossary()
        }
    }

    /// Lists all glossary entries for current session
    public func listGlossary() async -> [Glossary.Entry] {
        await ensureGlossaryLoaded()
        let glossary = glossaryForCurrentSession()
        return glossary.entries
    }

    /// Gets glossary for current session from SessionManagement
    public func glossaryForCurrentSession() -> Glossary {
        let sessionGlossary = sessionManager.glossaryForCurrentSession()

        // If session has a glossary, use it
        if !sessionGlossary.entries.isEmpty || sessionGlossary.domain != OrchestratorConstants.Defaults.domain {
            return sessionGlossary
        }

        // Otherwise use default glossary
        return defaultGlossary ?? Glossary(domain: OrchestratorConstants.Defaults.domain, entries: [])
    }

    /// Sets glossary for current session via SessionManagement
    public func setGlossaryForCurrentSession(_ glossary: Glossary) {
        sessionManager.setGlossaryForCurrentSession(glossary)
    }

    // MARK: - Session Initialization

    /// Initializes a new session with the default glossary
    public func initializeSessionGlossary() async {
        await ensureGlossaryLoaded()
        if let glossary = defaultGlossary {
            sessionManager.setGlossaryForCurrentSession(glossary)
        }
    }

    // MARK: - Acronym Policy Building

    /// Builds system policy for acronym handling
    public func buildAcronymSystemPolicy() async -> String {
        await ensureGlossaryLoaded()
        let glossary = glossaryForCurrentSession()

        if glossary.entries.isEmpty {
            return OrchestratorConstants.SystemMessages.noGlossaryMessage
        }

        return buildPolicyFromGlossary(glossary)
    }

    private func buildPolicyFromGlossary(_ glossary: Glossary) -> String {
        var policy = OrchestratorConstants.SystemMessages.acronymPolicyHeader

        // Add domain context
        policy += String(format: OrchestratorConstants.Glossary.domainLabel, glossary.domain)

        // Add glossary entries
        policy += OrchestratorConstants.Glossary.knownAcronymsLabel
        for entry in glossary.entries {
            policy += formatGlossaryEntry(entry)
        }

        // Add usage instructions
        policy += "\n\(OrchestratorConstants.SystemMessages.acronymPolicyInstructions)"

        return policy
    }

    private func formatGlossaryEntry(_ entry: Glossary.Entry) -> String {
        var formatted = String(format: OrchestratorConstants.Glossary.entryFormat, entry.acronym, entry.definition)

        if !entry.context.isEmpty {
            formatted += String(format: OrchestratorConstants.Glossary.contextFormat, entry.context)
        }

        if !entry.usage.isEmpty {
            formatted += String(format: OrchestratorConstants.Glossary.usageFormat, entry.usage)
        }

        formatted += OrchestratorConstants.Formatting.newline
        return formatted
    }

    // MARK: - Acronym Expansion

    /// Expands acronyms in user message based on glossary
    public func expandAcronyms(in message: String) async -> String {
        await ensureGlossaryLoaded()
        let glossary = glossaryForCurrentSession()
        return await AcronymResolver.expandFirstUse(
            in: message,
            glossary: glossary
        )
    }

    /// Resolves acronyms in response based on glossary
    public func resolveAcronyms(in response: String) async -> String {
        await ensureGlossaryLoaded()
        let glossary = glossaryForCurrentSession()
        // Use validateAndAmend instead of resolveInResponse
        let (amended, _) = await AcronymResolver.validateAndAmend(
            response: response,
            glossary: glossary
        )
        return amended
    }

    // MARK: - Glossary Management

    /// Adds an entry to the current session glossary
    public func addGlossaryEntry(_ entry: Glossary.Entry) {
        var glossary = glossaryForCurrentSession()
        glossary.entries.append(entry)
        setGlossaryForCurrentSession(glossary)
    }

    /// Removes an entry from the current session glossary
    public func removeGlossaryEntry(acronym: String) {
        var glossary = glossaryForCurrentSession()
        glossary.entries.removeAll { $0.acronym == acronym }
        setGlossaryForCurrentSession(glossary)
    }

    /// Updates an existing glossary entry
    public func updateGlossaryEntry(_ entry: Glossary.Entry) {
        var glossary = glossaryForCurrentSession()
        if let index = glossary.entries.firstIndex(where: { $0.acronym == entry.acronym }) {
            glossary.entries[index] = entry
            setGlossaryForCurrentSession(glossary)
        }
    }

    /// Searches for glossary entries matching a query
    public func searchGlossary(query: String) -> [Glossary.Entry] {
        let glossary = glossaryForCurrentSession()
        let lowercasedQuery = query.lowercased()

        return glossary.entries.filter { entry in
            entry.acronym.lowercased().contains(lowercasedQuery) ||
            entry.definition.lowercased().contains(lowercasedQuery) ||
            entry.context.lowercased().contains(lowercasedQuery)
        }
    }

    /// Clears the current session glossary
    public func clearSessionGlossary() {
        let emptyGlossary = Glossary(
            domain: defaultGlossary?.domain ?? OrchestratorConstants.Defaults.domain,
            entries: []
        )
        setGlossaryForCurrentSession(emptyGlossary)
    }

    /// Resets to default glossary
    public func resetToDefaultGlossary() async {
        await ensureGlossaryLoaded()
        if let glossary = defaultGlossary {
            setGlossaryForCurrentSession(glossary)
        }
    }

    // MARK: - Domain Management

    /// Changes the domain for the current session
    public func changeDomain(_ domain: String) {
        var glossary = glossaryForCurrentSession()
        glossary.domain = domain
        setGlossaryForCurrentSession(glossary)
    }

    /// Gets the current domain
    public var currentDomain: String {
        return glossaryForCurrentSession().domain
    }

    // MARK: - Default Glossary Access

    /// Gets the default glossary if loaded
    public func getDefaultGlossary() async -> Glossary? {
        await ensureGlossaryLoaded()
        return defaultGlossary
    }

    /// Reloads the glossary from YAML file
    public func reloadGlossary() async {
        defaultGlossary = nil
        await loadDefaultGlossary()
    }
}
