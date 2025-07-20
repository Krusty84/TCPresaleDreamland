//
//  BomGeneratorModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/06/2025.
//

import Foundation

/// Response wrapper that matches the JSON produced by `llmHelper.generateItemsPrompt`.
struct DeepSeekBOMResponse: Codable {
    let product: BOMItem
}

/// One node in the engineering Bill of Material.
/// Children are stored in `items`, so the structure can nest to any depth.
struct BOMItem: Codable, Identifiable, Equatable {
    let id = UUID()               // Unique per UI session (not sent to backend)
    let name: String              // Name suggested by LLM
    let desc: String              // Short description
    var items: [BOMItem] = []     // Sub-components
    var type: String = "Item"     // Default Teamcenter type
    var isEnabled: Bool = true    // User can untick to skip creation

    // Computed property for SwiftUI OutlineGroup
    var children: [BOMItem]? {
        items.isEmpty ? nil : items
    }

    // We only decode *name*, *desc*, and *items* – the other fields keep defaults.
    enum CodingKeys: String, CodingKey { case name, desc, items }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name  = try c.decode(String.self, forKey: .name)
        desc  = try c.decode(String.self, forKey: .desc)
        items = try c.decodeIfPresent([BOMItem].self, forKey: .items) ?? []
    }
}

/// Top-level wrapper that matches the JSON root { "product": { … } }
struct BOM: Codable {
    var product: BOMItem
}

/// Result returned after attempting to create the whole BOM in Teamcenter.
struct BOMCreationResult_OLD {
    let productName: String
    let success: Bool
}
