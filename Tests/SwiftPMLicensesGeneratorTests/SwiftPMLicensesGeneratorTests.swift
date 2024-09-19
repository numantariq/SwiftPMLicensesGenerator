import XCTest
import class Foundation.Bundle

final class LicencesGeneratorTests: XCTestCase {
    func testLicencesGeneration() throws {
        guard #available(macOS 10.13, *) else {
            XCTFail("Requires macOS 10.13 or newer to run")
            return
        }

#if !targetEnvironment(macCatalyst)
        let executableURL = URL(fileURLWithPath: #filePath)
            .pathComponents[..<(URL(fileURLWithPath: #filePath).pathComponents.firstIndex(of: "Tests") ?? 0)]
            .joined(separator: "/")
            .appending("/.build/debug/SwiftPMLicensesGenerator")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executableURL)

        // change dir to project root
        process.currentDirectoryURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        // Use default arguments for the `LicencesGenerator` command
        process.arguments = []

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            XCTFail("Failed to read output")
            return
        }

        XCTAssertTrue(output.contains("Licenses were successfully generated"), "Unexpected output: \(output)")
#endif
    }
}
