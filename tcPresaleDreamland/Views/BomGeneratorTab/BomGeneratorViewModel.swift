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
    @Published var rootBOMItemUid: String = "" // Teamcenter folder UID after creation
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
                    
                    func printJSON() {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: self.generatedBOM, options: .prettyPrinted)
                            if let jsonString = String(data: jsonData, encoding: .utf8) {
                            }
                        } catch {
                            print("Error converting JSON: \(error.localizedDescription)")
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
    func saveGeneratedBOMToHistory() async  {
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
    
    func createBOM1() async -> [ItemCreationResult] {
        var results: [ItemCreationResult] = []
        let settings = SettingsManager.shared
        let baseUrl = settings.tcURL
        
        print("👉 Starting BOM creation for domain:", domainName)
        // 1) Login
        print("🔑 Logging in to Teamcenter at", baseUrl)
        guard let sessionId = await tcApi.tcLogin(
            tcEndpointUrl: APIConfig.tcLoginUrl(tcUrl: baseUrl),
            userName:      settings.tcUsername,
            userPassword:  settings.tcPassword
        ) else {
            print("❌ Login failed. Aborting.")
            return generatedBOM
                .filter { $0.isEnabled }
                .map { ItemCreationResult(itemName: $0.name, success: false) }
        }
        print("✅ Logged in, JSESSIONID =", sessionId)
        
        // 2) Create a new container folder for this BOM
        print("📁 Creating container folder for BOM domain:", domainName)
        let (folderUid, folderCls, folderType) = await tcApi.createFolder(
            tcEndpointUrl: APIConfig.tcCreateFolder(tcUrl: baseUrl),
            name:          domainName,
            desc:          "Container for BOM of \(domainName)",
            containerUid:  settings.bomFolderUid,
            containerClassName: settings.bomFolderClassName,
            containerType: settings.bomFolderType
        )
        guard
            let containerUid = folderUid,
            let containerCls = folderCls,
            let containerTyp = folderType
        else {
            print("❌ Failed to create BOM container folder. Aborting.")
            return generatedBOM
                .filter { $0.isEnabled }
                .map { ItemCreationResult(itemName: $0.name, success: false) }
        }
        print("✅ Created BOM container folder:", containerUid)
        
        // 3) Close any old BOM windows
        print("🧹 Closing existing BOM windows")
        let closed = await tcApi.closeBOMWindows(
            tcEndpointUrl: APIConfig.closeBOMWindows(tcUrl: baseUrl)
        )
        print("🔒 Closed windows:", closed ?? [])
        
        var windowsToSave: [[String:Any]] = []
        var rootBOMRevUid: String? = nil // track bom root revision UID
        // Recursive helper
        func process(
            _ node: BOMItem,
            parentLineUid: String?
        ) async {
            guard node.isEnabled else {
                print("🚫 Skipping disabled item", node.name)
                return
            }
            print("🌱 Processing item", node.name, "level:", parentLineUid == nil ? "root" : "child")
            
            // 4) Create the Item
            //    - root item goes into the new BOM container folder
            //    - all others also into that same folder
            let (itemUid, itemRevUid) = await tcApi.createItem(
                tcEndpointUrl: APIConfig.tcCreateItem(tcUrl: baseUrl),
                name: node.name,
                type: node.type,
                description: node.desc,
                containerUid: containerUid,
                containerClassName: containerCls,
                containerType: containerTyp
            )
            let okCreate = (itemUid != nil && itemRevUid != nil)
            print(okCreate
                  ? "✅ Created item '\(node.name)': uid=\(itemUid!), rev=\(itemRevUid!)"
                  : "❌ Failed to create item '\(node.name)'")
            results.append(.init(itemName: node.name, success: okCreate))
            guard let uid = itemUid, let rev = itemRevUid else { return }
            
            var currentLineUid: String? = parentLineUid
            
            if parentLineUid == nil {
                // 5) Root level -> open BOM window on this new item
                // first (root) node → remember its revision UID
                rootBOMRevUid = rev
                print("📂 Creating BOM window for root item '\(node.name)'")
                let (winUid, lineUid) = await tcApi.createBOMWindows(
                    tcEndpointUrl: APIConfig.createBOMWindows(tcUrl: baseUrl),
                    itemUid: uid,
                    revRule:    "A",
                    unitNo:     1,
                    date:       "0001-01-01T00:00:00",
                    today:      true,
                    endItem:    uid,
                    endItemRevision: rev
                )
                if let w = winUid, let l = lineUid {
                    print("✅ BOM window:", w, "rootLine:", l)
                    windowsToSave.append([
                        "uid": w,
                        "className": "BOMWindow",
                        "type": "BOMWindow"
                    ])
                    currentLineUid = l
                } else {
                    print("❌ Failed to create BOM window for", node.name)
                    return
                }
            } else {
                // 6) Child level -> add under parentLineUid
                print("➕ Adding child '\(node.name)' under parent line \(parentLineUid!)")
                if let resp = await tcApi.addOrUpdateChildrenToParentLine(
                    tcEndpointUrl: APIConfig.addOrUpdateBOMLine(tcUrl: baseUrl),
                    parentLine: parentLineUid!,
                    createdItemRevUid: rev
                ) {
                    if let newLine = resp.itemLines?.first?.bomline.uid {
                        print("✅ Added child line UID =", newLine)
                        currentLineUid = newLine
                    } else {
                        print("⚠️ No new bomline returned for", node.name)
                    }
                } else {
                    print("❌ Failed to add child line for", node.name)
                }
            }
            
            // 7) Recurse into children
            for child in node.items {
                await process(child, parentLineUid: currentLineUid)
            }
        }
        
        // 8) Start processing
        for root in generatedBOM {
            await process(root, parentLineUid: nil)
        }
        
        // 9) Save windows
        print("💾 Saving all BOM windows:", windowsToSave)
        let saved = await tcApi.saveBOMWindows(
            tcEndpointUrl: APIConfig.saveBOMWindows(tcUrl: baseUrl),
            bomWindows: windowsToSave
        )
        print("✅ saveBOMWindows updated:", saved?.updated ?? [])
        
        // 10) Close windows
        print("🔒 Closing created BOM windows")
        let closed2 = await tcApi.closeBOMWindows(
            tcEndpointUrl: APIConfig.closeBOMWindows(tcUrl: baseUrl)
        )
        print("🔒 Closed windows:", closed2 ?? [])
        self.containerFolderUid = containerUid
        self.rootBOMItemUid = rootBOMRevUid ?? ""
        print("🏁 Finished BOM creation for", domainName)
        return results
    }
    
    func createBOM() async -> [ItemCreationResult] {
        let settings = SettingsManager.shared
        let baseUrl  = settings.tcURL
        var results: [ItemCreationResult] = []

        // ---------- 1) Log in first (same as createSelectedItems) ----------
        guard (await tcApi.tcLogin(
            tcEndpointUrl: APIConfig.tcLoginUrl(tcUrl: baseUrl),
            userName:      settings.tcUsername,
            userPassword:  settings.tcPassword
        )) != nil else {
            print("Login failed. Cannot create BOM.")
            return generatedBOM
                .filter { $0.isEnabled }
                .map { ItemCreationResult(itemName: $0.name, success: false) }
        }

        // ---------- 2) Guard against concurrent runs ----------
        guard !isLoading else { return [] }
        isLoading = true
        defer { isLoading = false }

        // ---------- 3) Create a container folder ----------
        let (folderUid, folderCls, folderType) = await tcApi.createFolder(
            tcEndpointUrl: APIConfig.tcCreateFolder(tcUrl: baseUrl),
            name:          domainName,
            desc:          "Container for BOM of \(domainName)",
            containerUid:  settings.bomFolderUid,
            containerClassName: settings.bomFolderClassName,
            containerType: settings.bomFolderType
        )

        guard
            let containerUid = folderUid,
            let containerCls = folderCls,
            let containerTyp = folderType
        else {
            // Folder creation failed → mark every enabled node as failed.
            return generatedBOM
                .filter { $0.isEnabled }
                .map { ItemCreationResult(itemName: $0.name, success: false) }
        }

        // ---------- 4) Close any old BOM windows ----------
        _ = await tcApi.closeBOMWindows(
            tcEndpointUrl: APIConfig.closeBOMWindows(tcUrl: baseUrl)
        )

        var windowsToSave: [[String:Any]] = []
        var rootBOMRevUid: String? = nil

        // ---------- 5) Recursive creator (same as your version) ----------
        func process(_ node: BOMItem, parentLineUid: String?) async {
            guard node.isEnabled else { return }

            // 5.1) Create the Item
            let (itemUid, itemRevUid) = await tcApi.createItem(
                tcEndpointUrl: APIConfig.tcCreateItem(tcUrl: baseUrl),
                name: node.name,
                type: node.type,
                description: node.desc,
                containerUid: containerUid,
                containerClassName: containerCls,
                containerType: containerTyp
            )
            let okCreate = (itemUid != nil && itemRevUid != nil)
            results.append(.init(itemName: node.name, success: okCreate))
            guard let uid = itemUid, let rev = itemRevUid else { return }

            var currentLineUid: String? = parentLineUid

            if parentLineUid == nil {
                // 5.2) Root → open BOM window
                rootBOMRevUid = rev
                let (winUid, lineUid) = await tcApi.createBOMWindows(
                    tcEndpointUrl: APIConfig.createBOMWindows(tcUrl: baseUrl),
                    itemUid: uid,
                    revRule:    "A",
                    unitNo:     1,
                    date:       "0001-01-01T00:00:00",
                    today:      true,
                    endItem:    uid,
                    endItemRevision: rev
                )
                if let w = winUid, let l = lineUid {
                    windowsToSave.append([
                        "uid": w,
                        "className": "BOMWindow",
                        "type": "BOMWindow"
                    ])
                    currentLineUid = l
                } else {
                    return
                }
            } else {
                // 5.3) Child → add under parent
                if let resp = await tcApi.addOrUpdateChildrenToParentLine(
                    tcEndpointUrl: APIConfig.addOrUpdateBOMLine(tcUrl: baseUrl),
                    parentLine: parentLineUid!,
                    createdItemRevUid: rev
                ) {
                    if let newLine = resp.itemLines?.first?.bomline.uid {
                        currentLineUid = newLine
                    }
                }
            }

            // 5.4) Recurse into children
            for child in node.items {
                await process(child, parentLineUid: currentLineUid)
            }
        }

        // ---------- 6) Start processing roots ----------
        for root in generatedBOM {
            await process(root, parentLineUid: nil)
        }

        // ---------- 7) Save & close windows ----------
        _ = await tcApi.saveBOMWindows(
            tcEndpointUrl: APIConfig.saveBOMWindows(tcUrl: baseUrl),
            bomWindows: windowsToSave
        )
        _ = await tcApi.closeBOMWindows(
            tcEndpointUrl: APIConfig.closeBOMWindows(tcUrl: baseUrl)
        )

        // Update for UI buttons
        self.containerFolderUid = containerUid
        self.rootBOMItemUid     = rootBOMRevUid ?? ""

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
