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
    //
    @Published var itemsTemperature: Double
    @Published var itemsMaxTokens: Int
    
    init() {
        // Initialize once from SettingsManager
        self.itemsTemperature = SettingsManager.shared.itemsTemperature
        self.itemsMaxTokens = SettingsManager.shared.itemsMaxTokens
    }
    
    func generateItems() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                
                let prompt = """
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
                Generate a list of \(count) real-world items related to the domain "\(domainName)" (e.g., Automotive, Aerospace, Medical Devices, etc.). Follow these rules:
                1. Only use actual industry-standard terms
                2. Descriptions must be 5-10 words
                3. Maintain technical accuracy
                
                Generate the output now for:
                Domain: \(domainName)
                Count: \(count)
                """
                
                // Call the DeepSeek API
                let response = try await deepSeekApi.chatLLM(
                    apiKey: SettingsManager.shared.apiKey,
                    prompt: prompt,
                    temperature:itemsTemperature,
                    max_tokens: itemsMaxTokens
                )
                
                // Parse the response
                if let choices = response["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // Clean the response
                    var cleanedContent = content
                    if content.contains("```json") {
                        cleanedContent = content
                            .replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    // Debug print the cleaned content
                    print("Cleaned JSON: \(cleanedContent)")
                    
                    // Decode the JSON
                    if let data = cleanedContent.data(using: .utf8) {
                        do {
                            let decodedResponse = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
                            await MainActor.run {
                                generatedItems = decodedResponse.items
                            }
                        } catch {
                            await MainActor.run {
                                errorMessage = "Failed to decode response: \(error.localizedDescription)"
                                print("DEBUG - Decoding error: \(error)")
                            }
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
