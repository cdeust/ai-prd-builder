import Foundation

public struct ChatOptions {
    public var injectContext: Bool
    public var useRefinement: Bool

    public init(
        injectContext: Bool = true,
        useRefinement: Bool = false
    ) {
        self.injectContext = injectContext
        self.useRefinement = useRefinement
    }
}