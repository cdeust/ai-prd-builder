import Foundation
import CommonModels

public protocol ResponseParser {
    func parseResponse(_ data: Data) throws -> String
}
