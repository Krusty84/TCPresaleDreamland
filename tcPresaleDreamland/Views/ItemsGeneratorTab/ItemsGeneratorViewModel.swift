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
    private let llmHelpser = LLMHelpers.shared
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
                // Call the DeepSeek API
                let response = try await deepSeekApi.chatLLM(
                    apiKey: SettingsManager.shared.apiKey,
                    prompt: llmHelpser.generateItemsPrompt(domainName: domainName, count: count),
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
    
    func saveGeneratedItemsToHistory() async {
        await dataStorageContext.perform {
            // 1. Create one history record
            let record = GeneratedItemsDataByLLM(context: self.dataStorageContext)
            record.id = UUID()                   // new unique ID for this batch
            record.name = self.domainName  // or whatever you call that field
            record.timestamp = Date()
            
            // 2. Encode the whole items array
            if let data = try? JSONEncoder().encode(self.generatedItems) {
                record.rawResponse = data
            } else {
                print("❌ Failed to JSON-encode generatedItems")
            }
            
            // 3. Save once
            do {
                try self.dataStorageContext.save()
            } catch {
                print("❌ Core Data save error:", error)
            }
        }
    }
    
    
    
    //    func createSelectedItems() async -> [ItemCreationResult] {
    //        guard !isLoading else { return [] }
    //        isLoading = true
    //        defer { isLoading = false }
    //
    //        // 1) Make the one folder for all new items
    //        let (folderUid, folderCls, folderType) = await tcApi.createFolder(
    //            tcEndpointUrl: APIConfig.tcCreateFolder(tcUrl: SettingsManager.shared.tcURL),
    //            name: domainName,
    //            desc: "Some items related to \(domainName)",
    //            containerUid: SettingsManager.shared.itemsFolderUid,
    //            containerClassName: SettingsManager.shared.itemsFolderClassName,
    //            containerType: SettingsManager.shared.itemsFolderType
    //        )
    //
    //        guard
    //            let containerUid = folderUid,
    //            let containerCls = folderCls,
    //            let containerTyp = folderType
    //        else {
    //            // If folder creation failed, mark all as failed
    //            return generatedItems
    //                .filter { $0.isEnabled }
    //                .map { ItemCreationResult(itemName: $0.name, success: false) }
    //        }
    //
    //        // 2) Loop and create each item inside that one folder
    //        var results: [ItemCreationResult] = []
    //        self.containerFolderUid=containerUid
    //        for item in generatedItems where item.isEnabled {
    //            let (newUid, newRev) = await tcApi.createItem(
    //                tcEndpointUrl: APIConfig.tcCreateItem(tcUrl: SettingsManager.shared.tcURL),
    //                name: item.name,
    //                type: item.type,
    //                description: item.desc,
    //                containerUid: containerUid,
    //                containerClassName: containerCls,
    //                containerType: containerTyp
    //            )
    //            let didSucceed = (newUid != nil && newRev != nil)
    //            results.append(.init(itemName: item.name, success: didSucceed))
    //        }
    //
    //        return results
    //    }
    
    func createSelectedItems() async -> [ItemCreationResult] {
        // 0) Login first
        guard (await tcApi.tcLogin(
            tcEndpointUrl: APIConfig.tcLoginUrl(tcUrl: SettingsManager.shared.tcURL),
            userName: SettingsManager.shared.tcUsername,
            userPassword: SettingsManager.shared.tcPassword
        )) != nil else {
            print("Login failed. Cannot create items.")
            // Mark all as failed
            return generatedItems
                .filter { $0.isEnabled }
                .map { ItemCreationResult(itemName: $0.name, success: false) }
        }
       
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
        self.containerFolderUid = containerUid

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
