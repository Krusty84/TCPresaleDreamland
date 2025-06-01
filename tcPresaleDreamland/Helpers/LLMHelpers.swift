//
//  LLMHelpers.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 24/05/2025.
//

import Foundation

class LLMHelpers:ObservableObject {
    static let shared = LLMHelpers()
    
    // Preparing prompt for BOM generating
    func generateBOMPrompt(for productName: String) -> String {
        return """
        Generate a Bill of Materials (BOM) for the specified product: \(productName). Return the BOM as a JSON object with the following structure: 
        {
          "product": "\(productName)",
          "components": [
            {
              "part_name": string,
              "part_number": string,
              "quantity": number,
              "material": string,
              "description": string,
              "supplier": string (optional)
            }
          ]
        }
        Ensure all components necessary for the assembly of \(productName) are listed comprehensively.
        """
    }
    
}


