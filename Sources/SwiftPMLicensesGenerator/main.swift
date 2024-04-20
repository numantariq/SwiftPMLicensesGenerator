import ArgumentParser
import Foundation

struct LicencesGenerator: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Build tool to generate a list of licenses for dependencies added via SwiftPM"
    )

    @Argument(
        help: "Path to the root directory of an Xcode project or Swift Package Manager project.",
        transform: { URL(fileURLWithPath: $0) }
    )
    var projectPath: URL = URL(fileURLWithPath: "./")

    @Option(
        help: "Path to where the output JSON file should be written to. Defaults to the current directory with 'licenses.json'.",
        transform: { URL(fileURLWithPath: $0) }
    )
    var outputJsonFile: URL = URL(fileURLWithPath: "./licenses.json")

    @Option(
        help: "Optional path to $BUILD_DIR. If not provided, uses the default path for DerivedData.",
        transform: { URL(fileURLWithPath: $0) }
    )
    var customBuildPath: URL?

    mutating func run() throws {
        var projectName: String
        var packageResolvedPath: URL

        if let xcodeprojPath = findXcodeprojPath(projectPath) {
            projectName = xcodeprojPath.deletingPathExtension().lastPathComponent
            packageResolvedPath = xcodeprojPath
                .appendingPathComponent("project.xcworkspace")
                .appendingPathComponent("xcshareddata")
                .appendingPathComponent("swiftpm")
                .appendingPathComponent("Package.resolved")
        } else if let packageResolvedURL = findPackageResolvedPath(projectPath) {
            projectName = projectPath.lastPathComponent
            packageResolvedPath = packageResolvedURL
        } else {
            throw ValidationError("Unable to locate an Xcode project or Package.resolved file in the provided path.")
        }

        let reposDirURL = try findCheckoutDir(projectName)
        let licensesInfo = try loadLicensesFromRepos(reposDirURL)

        var dependencies = try loadDependencies(from: packageResolvedPath)
        dependencies.updateWith(licensesInfo)

        try dependencies.writeAsJSON(toFile: outputJsonFile)

        print("Licenses were successfully generated and saved to: \(outputJsonFile.path)")
    }

    private var fileManager: FileManager { FileManager.default }

    private func findXcodeprojPath(_ projectPath: URL) -> URL? {
        let enumerator = FileManager.default.enumerator(atPath: projectPath.path)
        while let element = enumerator?.nextObject() as? String {
            if element.hasSuffix(".xcodeproj") {
                return projectPath.appendingPathComponent(element)
            }
        }
        return nil
    }

    private func findPackageResolvedPath(_ projectPath: URL) -> URL? {
        let packageResolvedURL = projectPath.appendingPathComponent("Package.resolved")
        if FileManager.default.fileExists(atPath: packageResolvedURL.path) {
            return packageResolvedURL
        }
        return nil
    }

    private func findCheckoutDir(_ projectName: String) throws -> URL {
        if let customBuildPath = customBuildPath {
            let checkoutsPath = customBuildPath.appendingPathComponent("SourcePackages/checkouts")
            guard fileManager.fileExists(
                atPath: checkoutsPath.path
            ) else {
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

        guard let projectDirectory = directoryContents
            .first(
                where: {
                    $0.starts(with: projectName)
                }
            ) else {
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

    private func loadLicensesFromRepos(_ reposDirURL: URL) throws -> [String: String] {
        let repos = try fileManager.contentsOfDirectory(atPath: reposDirURL.path)

        let repoLicenses: [String: String] = try repos.reduce(into: [:]) { dict, repo in
            let repoURL = reposDirURL.appendingPathComponent(repo)
            let repoFiles = try fileManager.contentsOfDirectory(
                at: repoURL,
                includingPropertiesForKeys: nil,
                options: []
            )

            let licenseURL = findLicenseFile(in: repoFiles)

            if  let licenseURL = licenseURL,
                let licenseData = fileManager.contents(atPath: licenseURL.path) {
                let license = String(decoding: licenseData, as: UTF8.self)
                dict[repo] = license
            }

        }

        return repoLicenses
    }

    private func loadDependencies(from resolvedPackageURL: URL) throws -> [Dependency] {
        guard let packageModel = try ResolvedPackageModel.loadResolvedPackageContent(resolvedPackageURL) else {
            print("Failed to load or decode package content from \(resolvedPackageURL)")
            return []
        }

        return packageModel.pins.compactMap { pin in
            guard let identity = pin.identity ?? pin.package,
                  let location = pin.location ?? pin.repositoryURL else {
                return nil
            }

            let version = pin.state.version ?? pin.state.revision

            return Dependency(
                name: identity,
                url: location,
                version: version
            )
        }
    }

    private func isValidLicenseFile(url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        return ["txt", "md", ""].contains(fileExtension)
    }

    private func findLicenseFile(in files: [URL]) -> URL? {
        if let licenseFileURL = findURLForFile(named: "license", in: files) {
            return licenseFileURL
        }

        // Some repos contain COPYING file with Copyright
        // information instead. Falling back to it if license not found
        return findURLForFile(named: "copying", in: files)
    }

    private func findURLForFile(named: String, in files: [URL]) -> URL? {
        return files.first { fileURL in
            let fileName = fileURL.lastPathComponent.lowercased()
            return (
                fileName.contains(named) &&
                fileURL.isFileURL &&
                isValidLicenseFile(url: fileURL)
            )
        }
    }
}

LicencesGenerator.main()
