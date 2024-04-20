//
//  ResolvedPackageModel.swift
//  
//
//  Created by Nouman Tariq on 22/10/2021.
//

import Foundation

struct ResolvedPackageModel: Decodable {
    struct Pin: Decodable {
        struct State: Decodable {
            let revision: String?
            let version: String?
        }

        let identity: String
        let location: String
        let state: State
    }

    let pins: [Pin]

    static func loadResolvedPackageContent(_ resolvedPackageURL: URL) throws -> ResolvedPackageModel? {
        guard let resolvedPackageData = FileManager.default.contents(atPath: resolvedPackageURL.path) else {
            return nil
        }

        return try JSONDecoder().decode(ResolvedPackageModel.self, from: resolvedPackageData)
    }
}
