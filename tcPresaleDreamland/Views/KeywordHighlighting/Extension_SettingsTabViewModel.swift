//
//  ExtensionSettingsTab.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 27/07/2025.
//

extension SettingsTabViewModel {
    
    var promptItemsKeywords: [String] {
        ["EXAMPLE INPUT:",
         "EXAMPLE JSON OUTPUT:",
         "RULES:",
         "ACTUAL TASK:",
         "{domainName}",
         "{count}"]
    }
    
    var promptBOMKeywords: [String] {
        ["EXAMPLE INPUT:",
         "EXAMPLE JSON OUTPUT:",
         "RULES:",
         "ACTUAL TASK:",
         "{productName}",
         "{depth}"]
    }
    
    var promptReqSpecKeywords: [String] {
        ["EXAMPLE INPUT:",
         "EXAMPLE JSON OUTPUT:",
         "RULES:",
         "ACTUAL TASK:",
         "{productName}",
         "{depth}"]
    }
    
    func missingItemsKeywords(in text: String) -> [String] {
        promptItemsKeywords.filter { !text.contains($0) }   // case-sensitive by design
    }
    
    func missingBOMKeywords(in text: String) -> [String] {
        promptBOMKeywords.filter { !text.contains($0) }   // case-sensitive by design
    }
    
    func missingReqSpecKeywords(in text: String) -> [String] {
        promptReqSpecKeywords.filter { !text.contains($0) }   // case-sensitive by design
    }
}
