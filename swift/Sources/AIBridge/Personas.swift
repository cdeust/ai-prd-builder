import Foundation

public struct StartupMVP: PersonaProfile {
    public let name = "Startup MVP"
    public let availabilitySLO = 99.9
    public let securityEmphasis = false
    public let latencySensitivityMs = 250
    public let adoptionAggressiveness = 3
    public init() {}
}

public struct EnterpriseIT: PersonaProfile {
    public let name = "Enterprise IT"
    public let availabilitySLO = 99.99
    public let securityEmphasis = true
    public let latencySensitivityMs = 150
    public let adoptionAggressiveness = 1
    public init() {}
}
