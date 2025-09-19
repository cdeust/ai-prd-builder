import XCTest
@testable import CommonModels

final class ChatMessageTests: XCTestCase {
    func testChatMessageCreation() {
        let message = ChatMessage(role: .user, content: "Test message")
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Test message")
    }

    func testChatMessageEquality() {
        let message1 = ChatMessage(role: .assistant, content: "Response")
        let message2 = ChatMessage(role: .assistant, content: "Response")
        XCTAssertEqual(message1, message2)
    }
}
