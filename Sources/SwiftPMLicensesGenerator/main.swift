import ArgumentParser
import ShellOut
import Foundation

struct LicencesGenerator: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract:
"""
Build tool to generate a list of licenses for
dependecies added via SwiftPM
"""
    )

    @Argument(help: "Path to derived data. $BUILD_DIR from Xcode run script")
    var buildDir: String

    @Option(name: .shortAndLong, help: "Path to .xcodeproj")
    var projectPath: String?

    @Option(name: .shortAndLong, help: "Path to .xcworkspace")
    var workspacePath: String?

    private var fileManager: FileManager {
        return FileManager.default
    }

//    @Argument(help: "Path to where the output JSON file should be written to")
//    var outputFile: String

    mutating func run() throws {
        let reposDirURL = computeReposDirURL(from: buildDir)
        let repoLicenses = try loadLicensesFromRepos(reposDirURL)
    }

    private func computeReposDirURL(from buildDir: String) -> URL {
        let buildDirPath = URL(fileURLWithPath: buildDir)

        // Go from: {DerivedData}/{AppFolder}/Build/Product
        // To: {DerivedData}/{AppFolder}
        let derivedDataURL = buildDirPath
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        // Go from: {DerivedData}/{AppFolder}
        // To: {DerivedData}/{AppFolder}/SourcePackages/checkouts
        let repoDirURL = derivedDataURL
            .appendingPathComponent("SourcePackages")
            .appendingPathComponent("checkouts")

        return repoDirURL
    }

    private func loadLicensesFromRepos(_ reposDirURL: URL) throws -> [String: String] {
        let repos = try fileManager.contentsOfDirectory(atPath: reposDirURL.path)

        let repoLicenses: [String: String] = try repos.reduce(into: [:]) { dict, repo in
            let repoURL = reposDirURL.appendingPathComponent(repo)
            let repoFiles = try fileManager.contentsOfDirectory(
                at: repoURL,
                includingPropertiesForKeys: nil,
                options: []
            )

            if let licenseURL = repoFiles.first(where: { fileURL in
                let fileName = fileURL.lastPathComponent.lowercased()
                return fileName.contains("license") && fileURL.isFileURL
            }) {
                if let licenseData = fileManager.contents(atPath: licenseURL.path) {
                    let license = String(decoding: licenseData, as: UTF8.self)
                    dict[repo] = license
                }
            }
        }

        return repoLicenses
    }
}

LicencesGenerator.main()
