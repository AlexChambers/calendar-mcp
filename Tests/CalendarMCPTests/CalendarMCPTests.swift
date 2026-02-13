import XCTest
@testable import CalendarMCP

final class CalendarMCPTests: XCTestCase {
    func testParsesSingleFramedMessage() throws {
        var codec = StdioMessageCodec()
        let payload = #"{"jsonrpc":"2.0","method":"initialize","id":1}"#
        let framed = "Content-Length: \(payload.utf8.count)\r\n\r\n\(payload)"
        codec.append(Data(framed.utf8))
        
        let message = try XCTUnwrap(codec.nextMessage())
        XCTAssertEqual(String(data: message, encoding: .utf8), payload)
    }
    
    func testParsesTwoFramedMessagesBackToBack() throws {
        var codec = StdioMessageCodec()
        let first = #"{"jsonrpc":"2.0","method":"initialize","id":1}"#
        let second = #"{"jsonrpc":"2.0","method":"tools/list","id":2}"#
        
        let stream = [
            "Content-Length: \(first.utf8.count)\r\n\r\n\(first)",
            "Content-Length: \(second.utf8.count)\r\n\r\n\(second)"
        ].joined()
        codec.append(Data(stream.utf8))
        
        let firstMessage = try XCTUnwrap(codec.nextMessage())
        XCTAssertEqual(String(data: firstMessage, encoding: .utf8), first)
        
        let secondMessage = try XCTUnwrap(codec.nextMessage())
        XCTAssertEqual(String(data: secondMessage, encoding: .utf8), second)
    }
    
    func testWaitsForCompleteFramedBodyAcrossChunks() throws {
        var codec = StdioMessageCodec()
        let payload = #"{"jsonrpc":"2.0","method":"tools/call","id":3}"#
        let frame = "Content-Length: \(payload.utf8.count)\r\n\r\n\(payload)"
        let splitIndex = frame.index(frame.startIndex, offsetBy: frame.count - 10)
        
        codec.append(Data(frame[..<splitIndex].utf8))
        XCTAssertNil(codec.nextMessage())
        
        codec.append(Data(frame[splitIndex...].utf8))
        let message = try XCTUnwrap(codec.nextMessage())
        XCTAssertEqual(String(data: message, encoding: .utf8), payload)
    }
    
    func testParsesLineDelimitedFallback() throws {
        var codec = StdioMessageCodec()
        let payload = #"{"jsonrpc":"2.0","method":"initialize","id":1}"#
        codec.append(Data("\(payload)\n".utf8))
        
        let message = try XCTUnwrap(codec.nextMessage())
        XCTAssertEqual(String(data: message, encoding: .utf8), payload)
    }
    
    func testSkipsMalformedContentLengthHeaderAndRecovers() throws {
        var codec = StdioMessageCodec()
        let payload = #"{"jsonrpc":"2.0","method":"tools/list","id":7}"#
        let stream = "Content-Length: abc\r\n\r\n\(payload)\n"
        codec.append(Data(stream.utf8))
        
        let message = try XCTUnwrap(codec.nextMessage())
        XCTAssertEqual(String(data: message, encoding: .utf8), payload)
    }
    
    func testSkipsNegativeContentLengthHeaderAndRecovers() throws {
        var codec = StdioMessageCodec()
        let payload = #"{"jsonrpc":"2.0","method":"tools/call","id":8}"#
        let stream = "Content-Length: -5\r\n\r\n\(payload)\n"
        codec.append(Data(stream.utf8))
        
        let message = try XCTUnwrap(codec.nextMessage())
        XCTAssertEqual(String(data: message, encoding: .utf8), payload)
    }
    
}
