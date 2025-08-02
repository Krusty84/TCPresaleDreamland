//
//  LLMHelpers.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 24/05/2025.
//

import Foundation

class LLMHelpers:ObservableObject {
    static let shared = LLMHelpers()
            
    func generateItemsPrompt(domainName: String, count: String) -> String {
        // read from AppStorage
        let template = SettingsManager.shared.itemsPrompt
        return template
            .replacingOccurrences(of: "{domainName}", with: domainName)
            .replacingOccurrences(of: "{count}",      with: count)
    }
    
    func generateBOMPrompt(productName: String, count: String) -> String {
        // read from AppStorage
        let template = SettingsManager.shared.bomPrompt
        return template
            .replacingOccurrences(of: "{productName}", with: productName)
            .replacingOccurrences(of: "{depth}",       with: count)
    }

    func generateReqSpecPrompt(productName: String, count: String) -> String {
        // read from AppStorage
        let template = SettingsManager.shared.reqSpecPrompt
        return template
            .replacingOccurrences(of: "{productName}", with: productName)
            .replacingOccurrences(of: "{depth}",       with: count)
    }
    
}
