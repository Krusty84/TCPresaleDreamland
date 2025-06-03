//
//  HomeFolderView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 03/06/2025.
//

// FolderSelectionView.swift

import SwiftUI

// Model for a folder item
struct FolderItem: Identifiable, Equatable {
    let id: String
    let name: String
}

public struct FolderSelectionView: View {
    // 1) Raw JSON data passed in (may be empty until "Get Some Data" is clicked)
    private let rawData: [[String: Any]]
    
    @State private var selectedItemsUid: String
    @State private var selectedBomsUid: String
    @State private var selectedRequirementsUid: String

    @State private var savedItemsName: String
    @State private var savedBomsName: String
    @State private var savedRequirementsName: String

    // 5) Compute only those entries where className == "Folder"
    private var folders: [FolderItem] {
        rawData.compactMap { dict in
            if
                let className = dict["className"] as? String,
                className == "Folder",
                let uid = dict["uid"] as? String,
                let name = dict["object_name"] as? String
            {
                return FolderItem(id: uid, name: name)
            }
            return nil
        }
    }

    // MARK: - Initializer
    public init(rawData: [[String: Any]]) {
        self.rawData = rawData
        
        // Read saved UID and name from SettingsManager
        let savedItemsUid = SettingsManager.shared.itemsFolderUid
        let savedItemsName = SettingsManager.shared.itemsFolderName
        
        let savedBomsUid = SettingsManager.shared.bomsFolderUid
        let savedBomsName = SettingsManager.shared.bomsFolderName
        
        let savedReqUid = SettingsManager.shared.requirementsFolderUid
        let savedReqName = SettingsManager.shared.requirementsFolderName
        
        // Initialize @State values
        _selectedItemsUid       = State(initialValue: savedItemsUid)
        _savedItemsName         = State(initialValue: savedItemsName)
        
        _selectedBomsUid        = State(initialValue: savedBomsUid)
        _savedBomsName          = State(initialValue: savedBomsName)
        
        _selectedRequirementsUid = State(initialValue: savedReqUid)
        _savedRequirementsName   = State(initialValue: savedReqName)
        
        
    }

    public var body: some View {
        HStack(spacing: 20) {
            // ─────────────────────── Items Column ───────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text("Items")
                    .font(.headline)
                Picker(selection: $selectedItemsUid, label: Text("")) {
                    Text("None").tag("")
                    // If folders are loaded, show them all
                    if !folders.isEmpty {
                        ForEach(folders) { folder in
                            Text(folder.name).tag(folder.id)
                        }
                    } else {
                        // No data yet: if user saved a folder, show that single saved entry
                        if !savedItemsName.isEmpty && selectedItemsUid == SettingsManager.shared.itemsFolderUid {
                           // Text(savedItemsName).tag(savedItemsUid)
                        }
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())
                .onChange(of: selectedItemsUid) { newUid in
                    // Save UID and name
                    SettingsManager.shared.itemsFolderUid = newUid
                    if let folderName = folders.first(where: { $0.id == newUid })?.name {
                        SettingsManager.shared.itemsFolderName = folderName
                        savedItemsName = folderName
                    } else {
                        // If newUid is "", clear name
                        SettingsManager.shared.itemsFolderName = ""
                        savedItemsName = ""
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // ────────────────────── BOM's Column ──────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text("BOM's")
                    .font(.headline)
                Picker(selection: $selectedBomsUid, label: Text("")) {
                    Text("None").tag("")
                    if !folders.isEmpty {
                        ForEach(folders) { folder in
                            Text(folder.name).tag(folder.id)
                        }
                    } else {
                        if !savedBomsName.isEmpty && selectedBomsUid == SettingsManager.shared.bomsFolderUid {
                          //  Text(savedBomsName).tag(savedBomsUid)
                        }
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())
                .onChange(of: selectedBomsUid) { newUid in
                    SettingsManager.shared.bomsFolderUid = newUid
                    if let folderName = folders.first(where: { $0.id == newUid })?.name {
                        SettingsManager.shared.bomsFolderName = folderName
                        savedBomsName = folderName
                    } else {
                        SettingsManager.shared.bomsFolderName = ""
                        savedBomsName = ""
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // ────────────────── Requirements Column ──────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text("Requirements")
                    .font(.headline)
                Picker(selection: $selectedRequirementsUid, label: Text("")) {
                    Text("None").tag("")
                    if !folders.isEmpty {
                        ForEach(folders) { folder in
                            Text(folder.name).tag(folder.id)
                        }
                    } else {
                        if !savedRequirementsName.isEmpty && selectedRequirementsUid == SettingsManager.shared.requirementsFolderUid {
                           // Text(savedRequirementsName).tag(savedRequirementsUid)
                        }
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())
                .onChange(of: selectedRequirementsUid) { newUid in
                    SettingsManager.shared.requirementsFolderUid = newUid
                    if let folderName = folders.first(where: { $0.id == newUid })?.name {
                        SettingsManager.shared.requirementsFolderName = folderName
                        savedRequirementsName = folderName
                    } else {
                        SettingsManager.shared.requirementsFolderName = ""
                        savedRequirementsName = ""
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        // 6) When view appears or folders change, validate selections
        .onAppear {
            validateSelections()
        }
        .onChange(of: folders) { _ in
            validateSelections()
        }
    }

    // MARK: - Helpers

    private func validateSelections() {
        // Only clear saved selection if folders are loaded and UID not found
        if !folders.isEmpty {
            if !folders.contains(where: { $0.id == selectedItemsUid }) {
                selectedItemsUid = ""
                SettingsManager.shared.itemsFolderUid = ""
                SettingsManager.shared.itemsFolderName = ""
                savedItemsName = ""
            }
            if !folders.contains(where: { $0.id == selectedBomsUid }) {
                selectedBomsUid = ""
                SettingsManager.shared.bomsFolderUid = ""
                SettingsManager.shared.bomsFolderName = ""
                savedBomsName = ""
            }
            if !folders.contains(where: { $0.id == selectedRequirementsUid }) {
                selectedRequirementsUid = ""
                SettingsManager.shared.requirementsFolderUid = ""
                SettingsManager.shared.requirementsFolderName = ""
                savedRequirementsName = ""
            }
        }
    }
}
