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

struct Item: Codable,Identifiable, Equatable {
    let id = UUID()
    let name: String
    let desc: String
    var type: String = "Item"  // Default value
    var isEnabled: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case name, desc
        // Don't include type here since it's not in the JSON
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        desc = try container.decode(String.self, forKey: .desc)
        // type gets its default value automatically
    }
}
