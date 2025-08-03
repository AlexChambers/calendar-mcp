// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CalendarMCP",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "calendar-mcp",
            targets: ["CalendarMCP"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "CalendarMCP",
            dependencies: [],
            path: "Sources/CalendarMCP",
            sources: ["SimpleServer.swift"],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
        .testTarget(
            name: "CalendarMCPTests",
            dependencies: ["CalendarMCP"],
            path: "Tests/CalendarMCPTests"
        )
    ]
)