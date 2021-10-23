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
}

extension Sequence where Element == Dependency {
    func writeAsJSON(toFile: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let outputVal = self.map { $0 }
        let jsonData = try encoder.encode(outputVal)
        try jsonData.write(to: toFile)
    }
}
