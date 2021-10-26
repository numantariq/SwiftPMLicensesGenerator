//
//  Dependency.swift
//  
//
//  Created by Nouman Tariq on 23/10/2021.
//

import Foundation

struct  Dependency: Codable {
    var name: String
    var url: String
    var version: String?
    var license: String?
    var organisation: String

    var repoName: String {
        guard let repoURL = URL(string: url) else {
            return ""
        }

        return repoURL
            .lastPathComponent
            .replacingOccurrences(of: ".git", with: "")
    }

    var authorName: String {
        guard let repoURL = URL(string: url) else {
            return ""
        }

        let components = repoURL.pathComponents
        if components.count > 1 {
            return components[1]
        }
        
        return ""
    }

    internal init(
        name: String,
        url: String,
        version: String? = nil
    ) {
        self.name = name
        self.url = url
        self.version = version
        self.license = nil
        self.organisation = ""
        self.organisation = self.authorName
    }
}

extension Sequence where Element == Dependency {
    func writeAsJSON(toFile: URL) throws {
        let encoder = JSONEncoder()
        let outputVal = self.map { $0 }
        let jsonData = try encoder.encode(outputVal)
        try jsonData.write(to: toFile)
    }

    mutating func updateWith(_ licensesInfo: [String: String]) {
        self = self.map { dependency -> Dependency in
            var result = dependency

            let repoNameFromURL = dependency.repoName

            if let matchingLicense = licensesInfo[repoNameFromURL] {
                result.license = matchingLicense
            }

            return result
        } as! Self
    }
}
