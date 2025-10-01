import Foundation
import CommonModels
import AIProvidersCore

public protocol LLMProviderProtocol {
    var name: String { get }
    func generate(_ req: LLMRequest) async throws -> LLMResponse
    func isAvailable() -> Bool
}
