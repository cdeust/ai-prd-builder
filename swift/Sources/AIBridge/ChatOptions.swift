import Foundation

public struct ChatOptions {
    public var injectContext: Bool
    public var twoPassRefine: Bool
    public var enforcePRD: Bool
    public var persona: PersonaProfile

    public init(
        injectContext: Bool = true,
        twoPassRefine: Bool = true,
        enforcePRD: Bool = false,
        persona: PersonaProfile = EnterpriseIT()
    ) {
        self.injectContext = injectContext
        self.twoPassRefine = twoPassRefine
        self.enforcePRD = enforcePRD
        self.persona = persona
    }
}
