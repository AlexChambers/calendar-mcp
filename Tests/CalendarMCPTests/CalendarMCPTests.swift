import XCTest
@testable import CalendarMCP

final class IntegrationTests: XCTestCase {
    private func launchServer() throws -> Process {
        let process = Process()
        // Use the debug build produced by `swift test`'s build step
        let binary = productsDirectory.appendingPathComponent("calendar-mcp")
        process.executableURL = binary
        return process
    }

    /// Directory containing built products (provided by SPM test runner).
    private var productsDirectory: URL {
        Bundle.allBundles
            .first { $0.bundlePath.hasSuffix(".xctest") }!
            .bundleURL
            .deletingLastPathComponent()
    }

    private func sendFramed(_ message: String, to pipe: Pipe) {
        let payload = Data(message.utf8)
        let header = "Content-Length: \(payload.count)\r\n\r\n"
        var frame = Data(header.utf8)
        frame.append(payload)
        pipe.fileHandleForWriting.write(frame)
    }

    private func readJSONLine(from pipe: Pipe, timeout: TimeInterval = 5) throws -> [String: Any] {
        let handle = pipe.fileHandleForReading
        let deadline = Date().addingTimeInterval(timeout)
        var buffer = Data()

        while Date() < deadline {
            let available = handle.availableData
            if available.isEmpty {
                usleep(50_000) // 50ms
                continue
            }
            buffer.append(available)
            if let newlineIndex = buffer.firstIndex(of: 0x0A) {
                let line = buffer[..<newlineIndex]
                let json = try XCTUnwrap(
                    JSONSerialization.jsonObject(with: line) as? [String: Any]
                )
                return json
            }
        }
        XCTFail("Timed out waiting for JSON response")
        return [:]
    }

    func testServerRespondsToInitializeWithStdinOpen() throws {
        let process = try launchServer()
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = FileHandle.nullDevice
        try process.run()

        defer {
            process.terminate()
            process.waitUntilExit()
        }

        let initMsg = #"{"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"0.1.0"}},"jsonrpc":"2.0","id":0}"#
        sendFramed(initMsg, to: stdinPipe)

        let response = try readJSONLine(from: stdoutPipe)
        XCTAssertEqual(response["jsonrpc"] as? String, "2.0")
        XCTAssertEqual(response["id"] as? Int, 0)

        let result = try XCTUnwrap(response["result"] as? [String: Any])
        XCTAssertNotNil(result["protocolVersion"])
        XCTAssertNotNil(result["serverInfo"])
        XCTAssertNotNil(result["capabilities"])
    }

    func testServerOutputIsNewlineDelimitedJSON() throws {
        let process = try launchServer()
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = FileHandle.nullDevice
        try process.run()

        defer {
            process.terminate()
            process.waitUntilExit()
        }

        let initMsg = #"{"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"0.1.0"}},"jsonrpc":"2.0","id":0}"#
        sendFramed(initMsg, to: stdinPipe)

        // Read raw bytes and verify format: JSON followed by newline, no Content-Length header
        let handle = stdoutPipe.fileHandleForReading
        let deadline = Date().addingTimeInterval(5)
        var buffer = Data()
        while Date() < deadline {
            let available = handle.availableData
            if !available.isEmpty {
                buffer.append(available)
                if buffer.contains(0x0A) { break }
            } else {
                usleep(50_000)
            }
        }

        let raw = try XCTUnwrap(String(data: buffer, encoding: .utf8))
        XCTAssertFalse(raw.hasPrefix("Content-Length"), "Output must not use Content-Length framing")
        XCTAssertTrue(raw.hasSuffix("\n"), "Output must end with a newline")

        // Verify the line is valid JSON
        let jsonLine = Data(raw.trimmingCharacters(in: .whitespacesAndNewlines).utf8)
        let parsed = try XCTUnwrap(JSONSerialization.jsonObject(with: jsonLine) as? [String: Any])
        XCTAssertEqual(parsed["jsonrpc"] as? String, "2.0")
    }

    func testServerHandlesFullHandshake() throws {
        let process = try launchServer()
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = FileHandle.nullDevice
        try process.run()

        defer {
            process.terminate()
            process.waitUntilExit()
        }

        // 1. Initialize
        let initMsg = #"{"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"0.1.0"}},"jsonrpc":"2.0","id":0}"#
        sendFramed(initMsg, to: stdinPipe)
        let initResponse = try readJSONLine(from: stdoutPipe)
        XCTAssertNotNil(initResponse["result"])

        // 2. Initialized notification (no response expected)
        let notifMsg = #"{"method":"notifications/initialized","jsonrpc":"2.0"}"#
        sendFramed(notifMsg, to: stdinPipe)

        // 3. Tools list
        let listMsg = #"{"method":"tools/list","jsonrpc":"2.0","id":1}"#
        sendFramed(listMsg, to: stdinPipe)
        let listResponse = try readJSONLine(from: stdoutPipe)
        XCTAssertEqual(listResponse["id"] as? Int, 1)

        let result = try XCTUnwrap(listResponse["result"] as? [String: Any])
        let tools = try XCTUnwrap(result["tools"] as? [[String: Any]])
        XCTAssertGreaterThan(tools.count, 0)

        let toolNames = tools.compactMap { $0["name"] as? String }
        XCTAssertTrue(toolNames.contains("calendar_list_events"))
        XCTAssertTrue(toolNames.contains("calendar_list_calendars"))
        XCTAssertTrue(toolNames.contains("calendar_create_event"))
    }

    func testServerReturnsErrorForUnknownMethod() throws {
        let process = try launchServer()
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = FileHandle.nullDevice
        try process.run()

        defer {
            process.terminate()
            process.waitUntilExit()
        }

        let msg = #"{"method":"bogus/method","jsonrpc":"2.0","id":99}"#
        sendFramed(msg, to: stdinPipe)
        let response = try readJSONLine(from: stdoutPipe)
        XCTAssertEqual(response["id"] as? Int, 99)

        let error = try XCTUnwrap(response["error"] as? [String: Any])
        XCTAssertEqual(error["code"] as? Int, -32601)
    }
}

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
