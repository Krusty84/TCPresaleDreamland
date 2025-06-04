//
//  ItemsGeneratorModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 04/06/2025.
//

import Foundation

struct DeepSeekResponse: Codable {
    let items: [Item]
}

struct Item: Codable {
    let name: String
    let desc: String
}
