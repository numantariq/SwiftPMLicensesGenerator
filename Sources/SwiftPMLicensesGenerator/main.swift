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

    @Argument(
        help: "Path to derived data. $BUILD_DIR from Xcode run script",
        transform: ({ return URL(fileURLWithPath: $0)})
    )
    var buildDir: URL

    @Argument(
        help: "Path to Package.resolved",
        transform: ({ return URL(fileURLWithPath: $0)})
    )
    var resolvedPackage: URL

    @Argument(
        help: "Path to where the output JSON file should be written to",
        transform: ({ return URL(fileURLWithPath: $0)})
    )
    var outputFile: URL

    private var fileManager: FileManager {
        return FileManager.default
    }

    private var derivedDataURL: URL {
        // Go from: {DerivedData}/{AppFolder}/Build/Product
        // To: {DerivedData}/{AppFolder}
        return buildDir
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private var reposDirURL: URL {
        // Go from: {DerivedData}/{AppFolder}
        // To: {DerivedData}/{AppFolder}/SourcePackages/checkouts
        return derivedDataURL
            .appendingPathComponent("SourcePackages")
            .appendingPathComponent("checkouts")
    }

    mutating func run() throws {
        let licensesInfo = try loadLicensesFromRepos(reposDirURL)

        var depenedencies = try loadDependencies(from: resolvedPackage)
        depenedencies.updateWith(licensesInfo)

        try depenedencies.writeAsJSON(toFile: outputFile)
    }

    private func loadLicensesFromRepos(_ reposDirURL: URL) throws -> [String: String] {
        let repos = try fileManager.contentsOfDirectory(atPath: reposDirURL.path)

        let repoLicenses: [String: String] = try repos.reduce(into: [:]) { dict, repo in
            let repoURL = reposDirURL.appendingPathComponent(repo)
            let repoFiles = try fileManager.contentsOfDirectory(at: repoURL,
                                                                includingPropertiesForKeys: nil,
                                                                options: []
            )

            let licenseURL = repoFiles.first { fileURL in
                let fileName = fileURL.lastPathComponent.lowercased()
                return fileName.contains("license") && fileURL.isFileURL
            }

            if  let licenseURL = licenseURL,
                let licenseData = fileManager.contents(atPath: licenseURL.path) {
                    let license = String(decoding: licenseData, as: UTF8.self)
                    dict[repo] = license
            }
        }

        return repoLicenses
    }

    private func loadDependencies(from resolvedPackageURL: URL) throws -> [Dependency] {
        let packageContent = try loadResolvedPackageContent(resolvedPackageURL)
        return packageContent?.object.pins.map({ pin in
            return Dependency(name: pin.package,
                              url: pin.repositoryURL,
                              version: pin.state.version,
                              license: nil)
        }) ?? []
    }

    private func loadResolvedPackageContent(_ resolvedPackageURL: URL) throws -> ResolvedPackageModel? {
        guard
            let resolvedPackageData = fileManager.contents(atPath: resolvedPackageURL.path)
        else {
            return nil
        }

        return try JSONDecoder().decode(ResolvedPackageModel.self,
                                                              from: resolvedPackageData)
    }
}

LicencesGenerator.main()
