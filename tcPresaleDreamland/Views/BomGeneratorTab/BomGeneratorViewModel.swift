//
//  ExampleViewModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import Foundation
import SwiftUI
import Combine

/// Observable object that drives the *Generate Items* screen.
/// It exposes published properties so SwiftUI will refresh
/// automatically when they change.
class BomGeneratorViewModel: ObservableObject {
    // MARK: - Private helpers
    /// Store Combine cancellables so the `sink` lives as long as the view‑model.
    private var cancellables = Set<AnyCancellable>()
    /// Singletons that talk to the backend services.
    private let tcApi       = TeamcenterAPIService.shared
    private let deepSeekApi = DeepSeekAPIService.shared
    private let llmHelpser  = LLMHelpers.shared

    // MARK: - Published state (drives the UI)
    @Published var domainName: String = ""        // "Airplane", "Radio", "Nuclear", ...
    @Published var containerFolderUid: String = "" // Teamcenter folder UID after creation
    @Published var count: String = ""             // How many items the user wants (String so it binds to TextField)
    @Published var generatedBOM: [BOMItem] = []     // Result list that the table shows
    @Published var isLoading: Bool = false         // Show progress spinner when true
    @Published var errorMessage: String?           // Non‑nil means we show an alert

    // MARK: - Generation parameters (bind to Steppers)
    @Published var bomTemperature: Double        // 0 → deterministic, 1 → very creative
    @Published var bomMaxTokens: Int             // LLM token limit
    @Published var itemTypes: [String] = []      // Allowed Teamcenter item types

    // MARK: - Core Data context
    private let dataStorageContext: NSManagedObjectContext

    // MARK: - Init
    init(
        storageController: NSManagedObjectContext = StorageController.shared.container.viewContext
    ) {
        // Initialize from persistent SettingsManager so we keep user choices.
        self.bomTemperature = SettingsManager.shared.bomTemperature
        self.bomMaxTokens   = SettingsManager.shared.bomMaxTokens
        self.itemTypes        = SettingsManager.shared.bomListOfTypes_storage
        self.dataStorageContext = storageController

        // Keep `itemTypes` in sync with SettingsManager at runtime.
        SettingsManager.shared.$bomListOfTypes_storage
            .sink { [weak self] newTypes in
                self?.itemTypes = newTypes
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API ----------------------------------------------------
    /// Ask the DeepSeek LLM to generate the BOM.
    func generateBOM() {
        Task {
            // Show spinner on main thread.
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }

            do {
                // Build the prompt and call DeepSeek.
                let response = try await deepSeekApi.chatLLM(
                    apiKey:     SettingsManager.shared.apiKey,
                    prompt:      llmHelpser.generateBOMPrompt(productName: domainName, count: count),
                    temperature: bomTemperature,
                    max_tokens:  bomMaxTokens
                )

                // Parse the standard OpenAI‑style JSON response.
                if let choices = response["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {

                    var cleanedContent = content
                    // If the model wrapped JSON in ```json ... ``` we strip it off.
                    if content.contains("```json") {
                        cleanedContent = content
                            .replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```",    with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }

                    // Try decoding the JSON into our `DeepSeekResponse` struct.
                    if let data = cleanedContent.data(using: .utf8) {
                        do {
                            let decodedResponse = try JSONDecoder().decode(DeepSeekBOMResponse.self, from: data)
                            //await MainActor.run { generatedBOM = [ decodedResponse.product ] + decodedResponse.product.items}
                            await MainActor.run { generatedBOM =  [decodedResponse.product]}
                        } catch {
                            await MainActor.run {
                                errorMessage = "Failed to decode response: \(error.localizedDescription)"
                                print("DEBUG - Decoding error:", error)
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate items: \(error.localizedDescription)"
                }
            }

            // Hide spinner.
            await MainActor.run { isLoading = false }
        }
    }

    /// Save the *current* generated items batch into Core Data history.
    /// We call this after the user presses *Save to History*.
    func saveGeneratedBOMToHistory() async {
        await dataStorageContext.perform {
            let record = GeneratedBOMDataByLLM(context: self.dataStorageContext)
            record.id        = UUID()       // Unique ID for this batch
            record.name      = self.domainName
            record.timestamp = Date()

            if let data = try? JSONEncoder().encode(self.generatedBOM) {
                record.rawResponse = data
            } else {
                print("❌ Failed to JSON‑encode generatedItems")
            }

            do {
                try self.dataStorageContext.save()
            } catch {
                print("❌ Core Data save error:", error)
            }
        }
    }

    /// Create all *selected* items inside Teamcenter and return a per‑item report.
    /// The call:
    /// 1. Logs in (once).
    /// 2. Creates a folder to hold the new items.
    /// 3. Iterates over `generatedItems` where `isEnabled == true` and
    ///    calls the *create item* REST API for each one.
    /// 4. Returns `[ItemCreationResult]` so the UI can show what failed.
    func createBOM() async -> [BOMCreationResult] {
        // ---------- 1) Log in first ----------
        guard (await tcApi.tcLogin(
            tcEndpointUrl: APIConfig.tcLoginUrl(tcUrl: SettingsManager.shared.tcURL),
            userName:      SettingsManager.shared.tcUsername,
            userPassword:  SettingsManager.shared.tcPassword
        )) != nil else {
            print("Login failed. Cannot create items.")
            return generatedBOM
                .filter { $0.isEnabled }
                .map { BOMCreationResult(productName: $0.name, success: false) }
        }

        // ---------- 2) Guard against concurrent runs ----------
        guard !isLoading else { return [] }
        isLoading = true
        defer { isLoading = false }

        // ---------- 3) Create a container folder ----------
        let (folderUid, folderCls, folderType) = await tcApi.createFolder(
            tcEndpointUrl: APIConfig.tcCreateFolder(tcUrl: SettingsManager.shared.tcURL),
            name:          domainName,
            desc:          "Some items related to \(domainName)",
            containerUid:  SettingsManager.shared.itemsFolderUid,
            containerClassName: SettingsManager.shared.itemsFolderClassName,
            containerType: SettingsManager.shared.itemsFolderType
        )

        guard
            let containerUid = folderUid,
            let containerCls = folderCls,
            let containerTyp = folderType
        else {
            // Folder creation failed → mark every enabled item as failed.
            return generatedBOM
                .filter { $0.isEnabled }
                .map { BOMCreationResult(productName: $0.name, success: false) }
        }

        // ---------- 4) Create items one by one ----------
        var results: [BOMCreationResult] = []
        self.containerFolderUid = containerUid  // So the UI can show *Open in TC* button.

        for item in generatedBOM where item.isEnabled {
            let (newUid, newRev) = await tcApi.createItem(
                tcEndpointUrl: APIConfig.tcCreateItem(tcUrl: SettingsManager.shared.tcURL),
                name:          item.name,
                type:          item.type,
                description:   item.desc,
                containerUid:  containerUid,
                containerClassName: containerCls,
                containerType: containerTyp
            )
            let didSucceed = (newUid != nil && newRev != nil)
            //results.append(.init(itemName: item.name, success: didSucceed))
        }

        return results
    }
    
    func setEnabled(id: UUID, to newValue: Bool) {
           // Disable entire subtree
           func disableAll(_ items: inout [BOMItem]) {
               for idx in items.indices {
                   items[idx].isEnabled = false
                   disableAll(&items[idx].items)
               }
           }

           @discardableResult
           func recurse(_ items: inout [BOMItem]) -> Bool {
               for idx in items.indices {
                   if items[idx].id == id {
                       // toggle this item
                       items[idx].isEnabled = newValue
                       // if unchecking, disable all descendants
                       if !newValue {
                           disableAll(&items[idx].items)
                       }
                       return true
                   }
                   // descend into children
                   if recurse(&items[idx].items) {
                       // if any child was toggled on, propagate enable upward
                       if newValue {
                           items[idx].isEnabled = true
                       }
                       return true
                   }
               }
               return false
           }

           // start recursion from the root list
           _ = recurse(&generatedBOM)
       }
    
    func updateAllItemTypes(to newType: String) {
        func recursivelyUpdateTypes(items: inout [BOMItem]) {
            for index in items.indices {
                items[index].type = newType
                recursivelyUpdateTypes(items: &items[index].items)
            }
        }
        
        recursivelyUpdateTypes(items: &generatedBOM)
    }
}
