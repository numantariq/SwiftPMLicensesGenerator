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
