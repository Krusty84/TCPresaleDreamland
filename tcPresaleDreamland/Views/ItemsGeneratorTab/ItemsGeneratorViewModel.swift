//
//  ExampleViewModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import Foundation

class ItemsGeneratorViewModel: ObservableObject {
    private let tcApi = TeamcenterAPIService.shared
    private let deepSeekApi = DeepSeekAPIService.shared
    @Published var domainName: String = ""
    @Published var count: String = ""
    @Published var generatedItems: [Item] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func generateItems() {
        print("callLled")
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                // Create a prompt for the LLM
                let prompt = """
                Generate a list of \(count) real-world items related to the domain "\(domainName)" (e.g., Automotive, Aerospace, Medical Devices, etc.).
                
                **Requirements:**
                - Return valid JSON with an array of objects, each containing:
                  - "name": String (actual product/component name).
                  - "desc": String (5-10 word max description).
                - Items must be industry-specific and real (no fictional terms).
                
                **Example Output (Automotive, 3 items):**
                ```json
                [
                  {
                    "name": "Turbocharger",
                    "desc": "Boosts engine power via forced induction."
                  },
                  {
                    "name": "OBD-II Scanner",
                    "desc": "Reads vehicle diagnostic trouble codes."
                  }
                ]
                """
                
                // Call the DeepSeek API
                let response = try await deepSeekApi.chatLLM(
                    apiKey: SettingsManager.shared.apiKey,
                    prompt: prompt
                )
                
                // Parse the response
                if let choices = response["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   var content = message["content"] as? String {
                    
                    // Clean the response (remove Markdown code block)
                    if content.starts(with: "```json") {
                        content = content
                            .replacingOccurrences(of: "```json\n", with: "")
                            .replacingOccurrences(of: "\n```", with: "")
                    }
                    
                    // Decode the JSON into [Item]
                    if let data = content.data(using: .utf8) {
                        let items = try JSONDecoder().decode([Item].self, from: data)
                        
                        await MainActor.run {
                            generatedItems = items
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate items: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct Item: Codable {
    let name: String
    let desc: String
}
