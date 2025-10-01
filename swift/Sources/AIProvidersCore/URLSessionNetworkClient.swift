import Foundation
import CommonModels

public final class URLSessionNetworkClient: NetworkClient {
    public init() {}

    public func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        return try await URLSession.shared.data(for: request)
    }
}
