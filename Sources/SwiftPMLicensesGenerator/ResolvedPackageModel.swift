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
            let revision: String
            let version: String?
            let branch: String?
        }

        let identity: String?
        let package: String?
        let repositoryURL: String?
        let location: String?
        let state: State
    }

    let pins: [Pin]
    let object: PinObject?
    let version: Int?

    struct PinObject: Decodable {
        let pins: [Pin]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let object = try container.decodeIfPresent(PinObject.self, forKey: .object) {
            self.pins = object.pins
            self.object = object
            self.version = try container.decodeIfPresent(Int.self, forKey: .version)
        } else {
            self.pins = try container.decode([Pin].self, forKey: .pins)
            self.object = nil
            self.version = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case pins
        case object
        case version
    }

    static func loadResolvedPackageContent(_ resolvedPackageURL: URL) throws -> ResolvedPackageModel? {
        guard let resolvedPackageData = FileManager.default.contents(atPath: resolvedPackageURL.path) else {
            return nil
        }

        return try JSONDecoder().decode(ResolvedPackageModel.self, from: resolvedPackageData)
    }
}
