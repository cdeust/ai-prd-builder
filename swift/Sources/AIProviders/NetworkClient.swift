import Foundation

/// Protocol for network operations (Single Responsibility Principle)
public protocol NetworkClient {
    func performRequest(_ request: URLRequest) async -> Result<Data, AIProviderError>
}

/// Default implementation of NetworkClient
public final class URLSessionNetworkClient: NetworkClient {
    private let session: URLSession
    private let responseValidator: ResponseValidator
    
    public init(session: URLSession = .shared, responseValidator: ResponseValidator = HTTPResponseValidator()) {
        self.session = session
        self.responseValidator = responseValidator
    }
    
    public func performRequest(_ request: URLRequest) async -> Result<Data, AIProviderError> {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            return responseValidator.validate(httpResponse, data: data)
                .map { _ in data }
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }
}

/// Protocol for response validation (Single Responsibility)
public protocol ResponseValidator {
    func validate(_ response: HTTPURLResponse, data: Data) -> Result<Void, AIProviderError>
}

/// HTTP response validator
public struct HTTPResponseValidator: ResponseValidator {
    public init() {}
    
    public func validate(_ response: HTTPURLResponse, data: Data) -> Result<Void, AIProviderError> {
        switch response.statusCode {
        case AIProviderConstants.StatusCodes.success:
            return .success(())
        case AIProviderConstants.StatusCodes.unauthorized,
             AIProviderConstants.StatusCodes.forbidden:
            return .failure(.invalidAPIKey)
        case AIProviderConstants.StatusCodes.tooManyRequests:
            return .failure(.rateLimitExceeded)
        case AIProviderConstants.StatusCodes.serverErrorStart...AIProviderConstants.StatusCodes.serverErrorEnd:
            return .failure(.serverError("Server returned status \(response.statusCode)"))
        default:
            return .failure(.networkError("Unexpected status code: \(response.statusCode)"))
        }
    }
}