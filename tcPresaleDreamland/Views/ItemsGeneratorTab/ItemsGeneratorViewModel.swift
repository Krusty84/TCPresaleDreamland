//
//  ExampleViewModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import Foundation
import SwiftUI
import Combine

class ItemsGeneratorViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let tcApi = TeamcenterAPIService.shared
    private let deepSeekApi = DeepSeekAPIService.shared
    @Published var domainName: String = ""
    @Published var containerFolderUid: String = ""
    @Published var count: String = ""
    @Published var generatedItems: [Item] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    //
    @Published var itemsTemperature: Double
    @Published var itemsMaxTokens: Int
    @Published var itemTypes: [String] = []
    //
    private let dataStorageContext: NSManagedObjectContext
  
    init(
        persistenceController: NSManagedObjectContext = PersistenceControllerGeneratedItemsData.shared.container.viewContext
    ) {
        // Initialize once from SettingsManager
        self.itemsTemperature = SettingsManager.shared.itemsTemperature
        self.itemsMaxTokens = SettingsManager.shared.itemsMaxTokens
        self.itemTypes = SettingsManager.shared.itemsListOfTypes_storage
        //
        self.dataStorageContext = persistenceController
        //
        SettingsManager.shared.$itemsListOfTypes_storage
                .sink { [weak self] newTypes in
                       self?.itemTypes = newTypes
                   }
                   .store(in: &cancellables)
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
    
    func saveGeneratedItemsToHistory() async -> (){
       await dataStorageContext.perform {
             for apiItem in self.generatedItems {
                 let stored = GeneratedItemsDataByLLM(context: self.dataStorageContext)
                 stored.id = apiItem.id            // keep the same UUID
                 stored.name = self.domainName
                 stored.timestamp = Date()         // now
                 // keep raw JSON in case you need it later:
                 stored.rawResponse = try? JSONEncoder()
                     .encode(apiItem)
             }
             
             do {
                 try self.dataStorageContext.save()
             } catch {
                 print("❌ Core Data save error:", error)
             }
         }
     }
    func createSelectedItems() async -> [ItemCreationResult] {
        guard !isLoading else { return [] }
        isLoading = true
        defer { isLoading = false }

        // 1) Make the one folder for all new items
        let (folderUid, folderCls, folderType) = await tcApi.createFolder(
            tcEndpointUrl: APIConfig.tcCreateFolder(tcUrl: SettingsManager.shared.tcURL),
            name: domainName,
            desc: "Some items related to \(domainName)",
            containerUid: SettingsManager.shared.itemsFolderUid,
            containerClassName: SettingsManager.shared.itemsFolderClassName,
            containerType: SettingsManager.shared.itemsFolderType
        )

        guard
            let containerUid = folderUid,
            let containerCls = folderCls,
            let containerTyp = folderType
        else {
            // If folder creation failed, mark all as failed
            return generatedItems
                .filter { $0.isEnabled }
                .map { ItemCreationResult(itemName: $0.name, success: false) }
        }

        // 2) Loop and create each item inside that one folder
        var results: [ItemCreationResult] = []
        self.containerFolderUid=containerUid
        for item in generatedItems where item.isEnabled {
            let (newUid, newRev) = await tcApi.createItem(
                tcEndpointUrl: APIConfig.tcCreateItem(tcUrl: SettingsManager.shared.tcURL),
                name: item.name,
                type: item.type,
                description: item.desc,
                containerUid: containerUid,
                containerClassName: containerCls,
                containerType: containerTyp
            )
            let didSucceed = (newUid != nil && newRev != nil)
            results.append(.init(itemName: item.name, success: didSucceed))
        }

        return results
    }
}
