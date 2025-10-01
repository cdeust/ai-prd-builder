import Foundation
import CommonModels

public protocol NetworkClient {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}
