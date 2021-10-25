# SwiftPMLicensesGenerator

A Swift Package to extract dependecies and licenses defined by SwiftPM. 
License is read from {Derived Data}/{App Folder}/SourcePackages/checkout. This is the path where Xcode checks out SPM dependencies. A license is only returned if the dependency has added a license file at the root of it's repo.
Rest of the information about the dependencies is extracted from the `Package.resolved` file. It can be found at following paths:

- For project: `{ProjectName}.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- For workspace: `{WorkspaceName}.xcworkspace/xcshareddata/swiftpm/Package.resolved`

## Usage

`swift run SwiftPMLicensesGenerator {$BUILD_DIR} {$PROJECT_DIR/ProjectName.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved} {$SRCROOT/licenses.json}`

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
- Tested with Xcode 13 on MacOS 11.6
