//
//  ResolvedPackageModel.swift
//  
//
//  Created by Nouman Tariq on 22/10/2021.
//

import Foundation

struct ResolvedPackageModel: Decodable {
    struct Object: Decodable {
        struct Pin: Decodable {
            struct State: Decodable {
                let branch: String?
                let revision: String?
                let version: String?
            }

            let package: String
            let repositoryURL: String
            let state: State
        }

        let pins: [Pin]
    }

    let object: Object

    static func loadResolvedPackageContent(_ resolvedPackageURL: URL) throws -> ResolvedPackageModel? {
        guard
            let resolvedPackageData = FileManager.default.contents(atPath: resolvedPackageURL.path)
        else {
            return nil
        }

        return try JSONDecoder().decode(ResolvedPackageModel.self,
                                                              from: resolvedPackageData)
    }
}

