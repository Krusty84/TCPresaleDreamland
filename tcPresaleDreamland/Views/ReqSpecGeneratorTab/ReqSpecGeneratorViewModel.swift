//
//  ExampleViewModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import Combine
import CoreData
import Foundation

@MainActor
class ReqSpecGeneratorViewModel: ObservableObject {
    // MARK: - Private helpers
    /// Store Combine cancellables so the `sink` lives as long as the view‑model.
    private var cancellables = Set<AnyCancellable>()
    /// Singletons that talk to the backend services.
    private let tcApi       = TeamcenterAPIService.shared
    private let deepSeekApi = DeepSeekAPIService.shared
    private let llmHelpser  = LLMHelpers.shared

    // MARK: - Published state (drives the UI)
    @Published var domainName: String = ""          // Product name: "Airplane", "Radio", ...
    @Published var containerFolderUid: String = ""  // Teamcenter folder UID after we create it
    @Published var rootReqSpecItemUid: String = ""      // Root ReqSpec item revision UID (for *Open in AWC*)
    @Published var count: String = ""               // How many top‑level items user wants (String for TextField binding)
    @Published var generatedReqSpec: [ReqSpecItem] = []     // Root nodes of the generated ReqSpec tree
    @Published var isLoading: Bool = false          // Show progress spinner when true
    @Published var errorMessage: String?            // Non‑nil means we show an alert
    @Published var statusMessage: String = ""       // Human‑friendly status line for the footer

    // MARK: - Generation parameters (bind to Steppers)
    @Published var reqSpecTemperature: Double           // 0 → deterministic, 1 → very creative
    @Published var reqSpecMaxTokens: Int                // LLM token limit
    @Published var itemTypes: [String] = []         // Allowed Teamcenter item types

    // MARK: - Core Data context
    private let dataStorageContext: NSManagedObjectContext

    // MARK: - Init
    init(
        storageController: NSManagedObjectContext = StorageController.shared.container.viewContext
    ) {
        // Initialize from persistent SettingsManager so we keep user choices.
        self.reqSpecTemperature     = SettingsManager.shared.reqSpecTemperature
        self.reqSpecMaxTokens       = SettingsManager.shared.reqSpecMaxTokens
        self.itemTypes          = SettingsManager.shared.reqSpecListOfTypes_storage
        self.dataStorageContext = storageController

        // Keep `itemTypes` in sync with SettingsManager at runtime.
        SettingsManager.shared.$reqSpecListOfTypes_storage
            .sink { [weak self] newTypes in
                self?.itemTypes = newTypes
            }
            .store(in: &cancellables)
    }

    // MARK: - Status
    /// Set a short status message on the main actor.
    private func setStatus(_ text: String) {
        Task { await MainActor.run { self.statusMessage = text } }
    }

    // MARK: - Public API ----------------------------------------------------
    /// Ask the DeepSeek LLM to generate the BOM.
    func generateReqSpec() {
        Task {
            // Show spinner on main thread.
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            setStatus("Generating Requirements Specification…")

            do {
                // Build the prompt and call DeepSeek.
                let response = try await deepSeekApi.chatLLM(
                    apiKey:      SettingsManager.shared.apiKey,
                    prompt:      llmHelpser.generateReqSpecPrompt(productName: domainName, count: count),
                    temperature: reqSpecTemperature,
                    max_tokens:  reqSpecMaxTokens
                )

                // Parse the standard OpenAI‑style JSON response.
                if let choices = response["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {

                    var cleanedContent = content
                    // If the model wrapped JSON in ```json … ``` strip it off.
                    if content.contains("```json") {
                        cleanedContent = content
                            .replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```",    with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }

                    // Try decoding the JSON into our `DeepSeekReqSpecResponse` struct.
                    if let data = cleanedContent.data(using: .utf8) {
                        do {
                            let decodedResponse = try JSONDecoder().decode(DeepSeekReqSpecResponse.self, from: data)
                            // Keep only the product root; its children live inside it.
                            await MainActor.run {
                                generatedReqSpec = [decodedResponse.reqSpec]
                                statusMessage = "Requirements Specification ready. Review items, then press “Push to TC”."
                            }
                        } catch {
                            await MainActor.run {
                                errorMessage = "Failed to decode response: \(error.localizedDescription)"
                                statusMessage = "Failed to decode LLM response. Check your system prompt."
                            }
                            print("DEBUG - Decoding error:", error)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate Requirements Specification: \(error.localizedDescription)"
                    statusMessage = "Failed to generate Requirements Specification."
                }
                print("Failed to generate Requirements Specification.", error.localizedDescription)
            }

            // Hide spinner.
            await MainActor.run { isLoading = false }
        }
    }

    /// Save the *current* generated BOM batch into Core Data history.
    /// We call this after the user presses *Save to History*.
    func saveGeneratedReqSpecToHistory() async {
        setStatus("Saving to history…")
        await dataStorageContext.perform {
            let record = GeneratedBOMDataByLLM(context: self.dataStorageContext)
            record.id        = UUID()       // Unique ID for this batch
            record.name      = self.domainName
            record.timestamp = Date()

            if let data = try? JSONEncoder().encode(self.generatedReqSpec) {
                record.rawResponse = data
            } else {
                print("❌ Failed to JSON‑encode generatedBOM")
            }

            do {
                try self.dataStorageContext.save()
            } catch {
                print("❌ Core Data save error:", error)
            }
        }
        setStatus("Saved to history.")
    }

    /// Create the whole BOM inside Teamcenter and return a per‑item report.
    /// The call:
    /// 1. Logs in.
    /// 2. Guards against concurrent runs.
    /// 3. Creates a folder to hold the new items.
    /// 4. Closes any old BOM windows.
    /// 5. Recursively creates items and BOM lines.
    /// 6. Saves & closes the windows.
    /// 7. Returns `[ItemCreationResult]` for the UI.
    func createReqSpec() async -> [ItemCreationResult] {
        let settings = SettingsManager.shared
        let baseUrl  = settings.tcURL
        var results: [ItemCreationResult] = []

        setStatus("Connecting to Teamcenter…")

        // ---------- 1) Log in first (same as createSelectedItems) ----------
        guard (await tcApi.tcLogin(
            tcEndpointUrl: APIConfig.tcLoginUrl(tcUrl: baseUrl),
            userName:      settings.tcUsername,
            userPassword:  settings.tcPassword
        )) != nil else {
            setStatus("Login failed. Check Teamcenter credentials.")
            print("Login failed. Cannot create BOM.")
            return generatedReqSpec
                .filter { $0.isEnabled }
                .map { ItemCreationResult(itemName: $0.name, success: false) }
        }

        // ---------- 2) Guard against concurrent runs ----------
        guard !isLoading else { return [] }
        isLoading = true
        defer { isLoading = false }

        // ---------- 3) Create a container folder ----------
        setStatus("Creating container folder…")
        let (folderUid, folderCls, folderType) = await tcApi.createFolder(
            tcEndpointUrl: APIConfig.tcCreateFolder(tcUrl: baseUrl),
            name:          domainName,
            desc:          "Container for Requirements Specification of \(domainName)",
            containerUid:  settings.reqSpecFolderUid,
            containerClassName: settings.reqSpecFolderClassName,
            containerType: settings.reqSpecFolderType
        )

        guard
            let containerUid = folderUid,
            let containerCls = folderCls,
            let containerTyp = folderType
        else {
            setStatus("Folder creation failed.")
            // Folder creation failed → mark every enabled node as failed.
            return generatedReqSpec
                .filter { $0.isEnabled }
                .map { ItemCreationResult(itemName: $0.name, success: false) }
        }

        // ---------- 4) Close any old BOM windows ----------
        _ = await tcApi.closeBOMWindows(
            tcEndpointUrl: APIConfig.closeBOMWindows(tcUrl: baseUrl)
        )

        var windowsToSave: [[String:Any]] = []
        var rootBOMRevUid: String? = nil

        // Progress helper (keeps text fresh without being noisy)
        func setProgress(_ text: String) {
            Task { await MainActor.run { self.statusMessage = text } }
        }

        // ---------- 5) Recursive creator ----------
        /// Create this node (and its children) inside TC.
        /// - `parentLineUid == nil` → this is the root node and we open a BOM window.
        func process(_ node: ReqSpecItem, parentLineUid: String?) async {
            guard node.isEnabled else { return }

            // 5.1) Create the Item
            setProgress("Creating “\(node.name)”…")
            let (itemUid, itemRevUid) = await tcApi.createItem(
                tcEndpointUrl: APIConfig.tcCreateItem(tcUrl: baseUrl),
                name: node.name,
                type: node.type,
                description: node.desc,
                containerUid: containerUid,
                containerClassName: containerCls,
                containerType: containerTyp
            )
            let didSucceed = (itemUid != nil && itemRevUid != nil)
            results.append(.init(itemName: node.name, success: didSucceed))
            guard let uid = itemUid, let rev = itemRevUid else { return }

            var currentLineUid: String? = parentLineUid

            if parentLineUid == nil {
                // 5.2) Root → open BOM window
                setProgress("Create BOM…")
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
                setProgress("Adding “\(node.name)” to parent…")
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
        for root in generatedReqSpec {
            await process(root, parentLineUid: nil)
        }

        // ---------- 7) Save & close windows ----------
        setProgress("Saving and closing BOM…")
        _ = await tcApi.saveBOMWindows(
            tcEndpointUrl: APIConfig.saveBOMWindows(tcUrl: baseUrl),
            bomWindows: windowsToSave
        )
        _ = await tcApi.closeBOMWindows(
            tcEndpointUrl: APIConfig.closeBOMWindows(tcUrl: baseUrl)
        )

        // Update for UI buttons (the footer view will show only the AWC link on success)
        self.containerFolderUid = containerUid
        self.rootReqSpecItemUid     = rootBOMRevUid ?? ""

        return results
    }

    /// Toggle `isEnabled` for the node with `id`.
    /// - If you disable a node → all its children are disabled too.
    /// - If you enable a node   → all its parents become enabled (so the path is visible).
    func setEnabled(id: UUID, to newValue: Bool) {
        // Disable entire subtree
        func disableAll(_ items: inout [ReqSpecItem]) {
            for idx in items.indices {
                items[idx].isEnabled = false
                disableAll(&items[idx].items)
            }
        }

        @discardableResult
        func recurse(_ items: inout [ReqSpecItem]) -> Bool {
            for idx in items.indices {
                if items[idx].id == id {
                    // Toggle this node
                    items[idx].isEnabled = newValue
                    // If unchecking, disable all descendants
                    if !newValue {
                        disableAll(&items[idx].items)
                    }
                    return true
                }
                // Descend into children
                if recurse(&items[idx].items) {
                    // If any child was toggled on, enable parents so the path stays visible
                    if newValue {
                        items[idx].isEnabled = true
                    }
                    return true
                }
            }
            return false
        }

        // Start recursion from the root list
        _ = recurse(&generatedReqSpec)
    }

    /// Change the Teamcenter item `type` on every node in the BOM tree.
    func updateAllItemTypes(to newType: String) {
        func recursivelyUpdateTypes(items: inout [ReqSpecItem]) {
            for index in items.indices {
                items[index].type = newType
                recursivelyUpdateTypes(items: &items[index].items)
            }
        }
        recursivelyUpdateTypes(items: &generatedReqSpec)
    }
}
