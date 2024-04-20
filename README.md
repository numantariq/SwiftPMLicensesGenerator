# SwiftPMLicensesGenerator

A Swift Package to extract dependecies and licenses defined by SwiftPM. 
License is read from {Derived Data}/{App Folder}/SourcePackages/checkout. This is the path where Xcode checks out SPM dependencies. A license is only returned if the dependency has added a license file at the root of it's repo.
Rest of the information about the dependencies is extracted from the `Package.resolved` file. It can be found at following paths:

## Usage Instructions

### Running the Licences Generator

The `LicencesGenerator` is a command-line tool designed to generate a list of licenses for dependencies added via Swift Package Manager by specifying the path to an Xcode project file. The tool automatically locates the `Package.resolved` file based on the provided project file path and generates a JSON file containing the licenses information.

Here’s how to run the generator from the command line:

```
swift run SwiftPMLicensesGenerator <PathToXcodeProj>
```

#### Parameters
- `<PathToXcodeProj>`: The path to the `.xcodeproj` file. This is used to derive the location of the `Package.resolved` file.
- `<PathToJsonOutputFile>`: (Optional) The path where the output JSON file containing the licenses should be written. Defaults to the current directory with the filename `licenses.json`.
- `--custom-build-path <PathToCustomBuildPath>`: (Optional) Specify a custom build directory path if not using the default DerivedData path. If provided, this path is used to locate the SourcePackages/checkouts directory.

### Output

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

## Example usage

Assuming your project is located at `ExampleProject.xcodeproj` and you prefer to save the output in the current directory:

```
swift run SwiftPMLicensesGenerator ExampleProject.xcodeproj
```

If you need to specify a custom build directory and a specific location for the output file:

```
swift run SwiftPMLicensesGenerator /path/to/ExampleProject.xcodeproj --custom-build-path /path/to/custom/build --output-json-file /path/to/output/licenses.json
```

## Note
- Only works with Swift Package Manager dependencies
- Developed in Swift
- `swift-tools-version:5.3`
- Tested with Xcode 15.3 on MacOS 14.3
