# SwiftPMLicensesGenerator

A Swift Package to extract dependecies and licenses defined by SwiftPM. 
License is read from {Derived Data}/{App Folder}/SourcePackages/checkout. This is the path where Xcode checks out SPM dependencies. A license is only returned if the dependency has added a license file at the root of it's repo.
Rest of the information about the dependencies is extracted from the `Package.resolved` file. It can be found at following paths:

## Usage Instructions

### Running the License Generator

To use the `LicencesGenerator`, you'll need to provide specific command-line arguments that specify the paths required for operation. The generator supports specifying a custom build directory, the path to the `Package.resolved` file, and the desired location for the output JSON file containing the license details.

Here’s how to run the generator from the command line:

```bash
swift run SwiftPMLicensesGenerator --project-name <ProjectName> --build-dir <PathToCustomBuildDir> --resolved-package <PathToPackage.resolved> --output-file <PathToOutputFile>
```

#### Parameters
--project-name <ProjectName>: Specify the project name to determine the correct DerivedData directory if --build-dir is not provided.

--build-dir <PathToCustomBuildDir>: (Optional) Specify a custom build directory path if not using the default DerivedData path. If provided, this path is used to locate the SourcePackages/checkouts directory.

--resolved-package <PathToPackage.resolved>: Specify the full path to the Package.resolved file typically located inside your Xcode project workspace.

--output-file <PathToOutputFile>: Specify the path where the output JSON file containing the licenses should be written.

## Example

Assuming your project is named "ExampleProject", and you want to use the default DerivedData directory, your command might look like this:

```bash
swift run SwiftPMLicensesGenerator --project-name ExampleProject --resolved-package ExampleProject.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved --output-file licenses.json
```

If you wish to specify a custom build directory:

```bash
swift run SwiftPMLicensesGenerator --build-dir /path/to/custom/build --resolved-package ExampleProject.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved --output-file licenses.json
```

## Note
Ensure that the paths you provide are absolute and correct according to your filesystem and project structure. The script will validate these paths and will provide an error message if any issues are found.

## Output

The output JSON uses the following format:

```JSON
[
    {
        "license":"License Text",
        "name":"Package Name",
        "url":"URL where package is hosted",
        "organisation": "Only tested for github URLs"
        "version":"Version Number being used in the project"
    }
]
```

## Notes
- Only works with Swift Package Manager dependencies
- Developed in Swift
- `swift-tools-version:5.3`
- Tested with Xcode 15.3 on MacOS 14.3
