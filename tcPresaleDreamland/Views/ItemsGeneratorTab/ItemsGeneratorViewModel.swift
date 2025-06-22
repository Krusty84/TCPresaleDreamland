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
class ItemsGeneratorViewModel: ObservableObject {
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
    @Published var generatedItems: [Item] = []     // Result list that the table shows
    @Published var isLoading: Bool = false         // Show progress spinner when true
    @Published var errorMessage: String?           // Non‑nil means we show an alert

    // MARK: - Generation parameters (bind to Steppers)
    @Published var itemsTemperature: Double        // 0 → deterministic, 1 → very creative
    @Published var itemsMaxTokens: Int             // LLM token limit
    @Published var itemTypes: [String] = []        // Allowed Teamcenter item types

    // MARK: - Core Data context
    private let dataStorageContext: NSManagedObjectContext

    // MARK: - Init
    init(
        persistenceController: NSManagedObjectContext = PersistenceControllerGeneratedItemsData.shared.container.viewContext
    ) {
        // Initialize from persistent SettingsManager so we keep user choices.
        self.itemsTemperature = SettingsManager.shared.itemsTemperature
        self.itemsMaxTokens   = SettingsManager.shared.itemsMaxTokens
        self.itemTypes        = SettingsManager.shared.itemsListOfTypes_storage
        self.dataStorageContext = persistenceController

        // Keep `itemTypes` in sync with SettingsManager at runtime.
        SettingsManager.shared.$itemsListOfTypes_storage
            .sink { [weak self] newTypes in
                self?.itemTypes = newTypes
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API ----------------------------------------------------
    /// Ask the DeepSeek LLM to generate the items list.
    func generateItems() {
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
                    prompt:      llmHelpser.generateItemsPrompt(domainName: domainName, count: count),
                    temperature: itemsTemperature,
                    max_tokens:  itemsMaxTokens
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
                            let decodedResponse = try JSONDecoder().decode(DeepSeektemsResponse.self, from: data)
                            await MainActor.run { generatedItems = decodedResponse.items }
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
    func saveGeneratedItemsToHistory() async {
        await dataStorageContext.perform {
            let record = GeneratedItemsDataByLLM(context: self.dataStorageContext)
            record.id        = UUID()       // Unique ID for this batch
            record.name      = self.domainName
            record.timestamp = Date()

            if let data = try? JSONEncoder().encode(self.generatedItems) {
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
    func createSelectedItems() async -> [ItemCreationResult] {
        // ---------- 1) Log in first ----------
        guard (await tcApi.tcLogin(
            tcEndpointUrl: APIConfig.tcLoginUrl(tcUrl: SettingsManager.shared.tcURL),
            userName:      SettingsManager.shared.tcUsername,
            userPassword:  SettingsManager.shared.tcPassword
        )) != nil else {
            print("Login failed. Cannot create items.")
            return generatedItems
                .filter { $0.isEnabled }
                .map { ItemCreationResult(itemName: $0.name, success: false) }
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
            return generatedItems
                .filter { $0.isEnabled }
                .map { ItemCreationResult(itemName: $0.name, success: false) }
        }

        // ---------- 4) Create items one by one ----------
        var results: [ItemCreationResult] = []
        self.containerFolderUid = containerUid  // So the UI can show *Open in TC* button.

        for item in generatedItems where item.isEnabled {
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
            results.append(.init(itemName: item.name, success: didSucceed))
        }

        return results
    }
}
