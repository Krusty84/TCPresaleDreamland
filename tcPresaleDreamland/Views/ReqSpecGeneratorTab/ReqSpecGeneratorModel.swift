//
//  ReqSpecGeneratorModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 02/08/2025.
//

import Foundation

/// Response wrapper that matches the JSON produced by `llmHelper.generateItemsPrompt`.
struct DeepSeekReqSpecResponse: Codable {
    let reqSpec: ReqSpecItem
}

/// One node in the engineering Bill of Material.
/// Children are stored in `items`, so the structure can nest to any depth.
struct ReqSpecItem: Codable, Identifiable, Equatable {
    let id = UUID()               // Unique per UI session (not sent to backend)
    let name: String              // Name suggested by LLM
    let desc: String              // Short description
    var items: [ReqSpecItem] = []     // Sub-components
    var type: String = "Item"     // Default Teamcenter type
    var isEnabled: Bool = true    // User can untick to skip creation

    // Computed property for SwiftUI OutlineGroup
    var children: [ReqSpecItem]? {
        items.isEmpty ? nil : items
    }

    // We only decode *name*, *desc*, and *items* – the other fields keep defaults.
    enum CodingKeys: String, CodingKey { case name, desc, items }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name  = try c.decode(String.self, forKey: .name)
        desc  = try c.decode(String.self, forKey: .desc)
        items = try c.decodeIfPresent([ReqSpecItem].self, forKey: .items) ?? []
    }
}

/// Top-level wrapper that matches the JSON root { "product": { … } }
struct ReqSpec: Codable {
    var reqSpec: ReqSpecItem
}
