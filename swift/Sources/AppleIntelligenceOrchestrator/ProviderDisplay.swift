import Foundation
import AIBridge

/// Handles display of AI provider information
public struct ProviderDisplay {

    /// Displays available AI providers with their status indicators
    ///
    /// - Parameters:
    ///   - providers: List of available providers
    ///   - allowExternal: Whether external providers are allowed
    public static func displayAvailableProviders(
        _ providers: [Orchestrator.AIProvider],
        allowExternal: Bool
    ) {
        print(OrchestratorConstants.Privacy.availableProviders)

        for provider in providers {
            let indicator = getProviderIndicator(provider, allowExternal: allowExternal)
            displayProvider(provider, indicator: indicator)
        }
    }

    /// Displays the privacy policy information
    public static func displayPrivacyPolicy() {
        print(OrchestratorConstants.Privacy.policyHeader)
        for item in OrchestratorConstants.Privacy.policyItems {
            print(item)
        }
        print("")
    }

    /// Displays privacy mode status
    ///
    /// - Parameter allowExternal: Whether external providers are allowed
    public static func displayPrivacyMode(allowExternal: Bool) {
        if allowExternal {
            print(OrchestratorConstants.Privacy.externalEnabled)
        } else {
            print(OrchestratorConstants.Privacy.privacyMode)
        }
    }

    // MARK: - Private Helpers

    private static func getProviderIndicator(
        _ provider: Orchestrator.AIProvider,
        allowExternal: Bool
    ) -> String {
        switch provider {
        case .foundationModels:
            return OrchestratorConstants.ProviderIndicator.onDevice

        case .privateCloudCompute:
            return OrchestratorConstants.ProviderIndicator.privacyPreserved

        case .anthropic, .openai, .gemini:
            return allowExternal ?
                OrchestratorConstants.ProviderIndicator.external :
                OrchestratorConstants.ProviderIndicator.disabled
        }
    }

    private static func displayProvider(_ provider: Orchestrator.AIProvider, indicator: String) {
        print("\(OrchestratorConstants.UI.bullet)\(provider.rawValue)\(indicator)")
    }
}