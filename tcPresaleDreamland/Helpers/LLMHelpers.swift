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
       return """
        You are a domain expert who converts industry-specific items into perfect JSON format.
        
        EXAMPLE INPUT:
        Domain: Automotive
        Count: 2
        
        EXAMPLE JSON OUTPUT:
        {
            "items": [
                {
                    "name": "Turbocharger",
                    "desc": "Boosts engine power via forced induction"
                },
                {
                    "name": "OBD-II Scanner",
                    "desc": "Reads vehicle diagnostic trouble codes"
                }
            ]
        }
        
        ACTUAL TASK:
        Generate a list of \(count) real-world items related to the domain "\(domainName)" (e.g., Automotive, Aerospace, Medical Devices, Electronics, etc.). Follow these rules:
        1. Only use actual industry-standard terms
        2. Descriptions must be 5-10 words
        3. Maintain technical accuracy
        
        Generate the output now for:
        Domain: \(domainName)
        Count: \(count)
        """
    }
    
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


