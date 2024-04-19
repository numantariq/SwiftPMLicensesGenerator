import ArgumentParser
import Foundation

struct LicencesGenerator: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Build tool to generate a list of licenses for dependencies added via SwiftPM"
    )

    @Option(name: .long, help: "Project name to determine the correct DerivedData directory.")
    var projectName: String

    @Option(name: .long, help: "Path to derived data. $BUILD_DIR from Xcode run script. If not provided, uses the default DerivedData path.")
    var buildDir: String?

    @Option(name: .long, help: "Path to Package.resolved")
    var resolvedPackage: String

    @Option(name: .long, help: "Path to where the output JSON file should be written to")
    var outputFile: String

    mutating func run() throws {
        let checkoutsDirURL = try findCheckoutsDirectory()
        let licenses = try generateLicenses(from: checkoutsDirURL)

        let outputURL = URL(fileURLWithPath: outputFile)
        try writeLicenses(licenses, to: outputURL)

        print("Licenses were successfully generated and saved to: \(outputURL.path)")
    }

    private var fileManager: FileManager {
        return FileManager.default
    }

    private func findCheckoutsDirectory() throws -> URL {
        if let buildDirPath = buildDir {
            let customBuildDirURL = URL(fileURLWithPath: buildDirPath)
            let checkoutsPath = customBuildDirURL.appendingPathComponent("SourcePackages/checkouts")
            guard fileManager.fileExists(atPath: checkoutsPath.path) else {
                throw ValidationError("The 'checkouts' folder does not exist at custom build path: \(checkoutsPath.path)")
            }
            return checkoutsPath
        }

        let derivedDataPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Developer")
            .appendingPathComponent("Xcode")
            .appendingPathComponent("DerivedData")

        let directoryContents = try fileManager.contentsOfDirectory(atPath: derivedDataPath.path)
        guard let projectDirectory = directoryContents.first(where: { $0.starts(with: projectName) }) else {
            throw ValidationError("No DerivedData directory found for project named \(projectName).")
        }

        let fullProjectPath = derivedDataPath
            .appendingPathComponent(projectDirectory)
            .appendingPathComponent("SourcePackages/checkouts")

        guard fileManager.fileExists(atPath: fullProjectPath.path) else {
            throw ValidationError("The 'checkouts' folder does not exist at derived path: \(fullProjectPath.path)")
        }

        return fullProjectPath
    }

    private func generateLicenses(from directory: URL) throws -> [String: String] {
        let repos = try fileManager.contentsOfDirectory(atPath: directory.path)
        var licenses: [String: String] = [:]

        for repo in repos {
            let repoURL = directory.appendingPathComponent(repo)
            let licenseFile = repoURL.appendingPathComponent("LICENSE", isDirectory: false)
            if fileManager.fileExists(atPath: licenseFile.path),
               let licenseData = fileManager.contents(atPath: licenseFile.path) {
                let licenseContent = String(decoding: licenseData, as: UTF8.self)
                licenses[repo] = licenseContent
            } else {
                licenses[repo] = "No license file found."
            }
        }
        return licenses
    }

    private func writeLicenses(_ licenses: [String: String], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(licenses)
        try jsonData.write(to: url)
    }
}

LicencesGenerator.main()
