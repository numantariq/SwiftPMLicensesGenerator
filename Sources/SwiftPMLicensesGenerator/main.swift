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

    @Argument(help: "Path to Package.resolved")
    var resolvedPackage: String

    @Argument(
        help: "Path to where the output JSON file should be written to",
        transform: ({ return URL(fileURLWithPath: $0)})
    )
    var outputFile: URL

    private var fileManager: FileManager {
        return FileManager.default
    }

    mutating func run() throws {
        let reposDirURL = computeReposDirURL(from: buildDir)
        let licensesInfo = try loadLicensesFromRepos(reposDirURL)

        let depenedencies = try loadDependencies(from: resolvedPackage)

        let dependencyLicenses: [Dependency] = depenedencies.map { dependency in
            guard let dependencyURL = URL(string: dependency.url) else {
                print("Unable to create URL instance")
                return dependency
            }

            var result = dependency

            let repoNameFromURL = dependencyURL
                .lastPathComponent
                .replacingOccurrences(of: ".git", with: "")

            if let matchingLicense = licensesInfo[repoNameFromURL] {
                result.license = matchingLicense
            }

            return result
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(dependencyLicenses)
        try jsonData.write(to: outputFile)
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

    private func loadDependencies(from resolvedPackage: String) throws -> [Dependency] {
        let packageContent = try loadResolvedPackageContent(resolvedPackage)
        return packageContent?.object.pins.map({ pin in
            return Dependency(name: pin.package,
                              url: pin.repositoryURL,
                              version: pin.state.version,
                              license: nil)
        }) ?? []
    }

    private func loadResolvedPackageContent(_ resolvedPackage: String) throws -> ResolvedPackageModel? {
        let resolvedPackageURL = URL(fileURLWithPath: resolvedPackage)

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
