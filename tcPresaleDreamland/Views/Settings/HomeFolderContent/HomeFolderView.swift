//
//  HomeFolderView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 03/06/2025.
//

import SwiftUI

public struct HomeFolderContent: View {
    // MARK: - Input ---------------------------------------------------------
    /// Raw response from Teamcenter REST (array of dictionaries).
    private let rawData: [[String: Any]]

    // MARK: - UI state ------------------------------------------------------
    // We keep both the *selected UID* *and* the last known metadata so that
    // we can still show a name in the picker when the UID disappeared.
    @State private var selectedItemsUid: String
    @State private var selectedBomsUid: String
    @State private var selectedRequirementsUid: String

    @State private var savedItemsName: String
    @State private var savedItemsClassName: String
    @State private var savedItemsType: String

    @State private var savedBomsName: String
    @State private var savedBomsClassName: String
    @State private var savedBomsType: String

    @State private var savedRequirementsName: String
    @State private var savedRequirementsClassName: String
    @State private var savedRequirementsType: String

    // MARK: - Derived folders list -----------------------------------------
    /// We only care about objects whose `className` is exactly "Folder".
    private var folders: [FolderItem] {
        rawData.compactMap { dict in
            guard
                let className = dict["className"] as? String, className == "Folder",
                let uid  = dict["uid"] as? String,
                let name = dict["object_name"] as? String,
                let type = dict["type"] as? String
            else { return nil }
            return FolderItem(id: uid, name: name, className: className, type: type)
        }
    }

    // MARK: - Init ----------------------------------------------------------
    public init(rawData: [[String: Any]]) {
        self.rawData = rawData
        // Load persisted choices from SettingsManager ----------------------
        let s = SettingsManager.shared

        _selectedItemsUid        = State(initialValue: s.itemsFolderUid)
        _selectedBomsUid         = State(initialValue: s.bomFolderUid)
        _selectedRequirementsUid = State(initialValue: s.reqSpecFolderUid)

        _savedItemsName       = State(initialValue: s.itemsFolderName)
        _savedItemsClassName  = State(initialValue: s.itemsFolderClassName)
        _savedItemsType       = State(initialValue: s.itemsFolderType)

        _savedBomsName       = State(initialValue: s.bomFolderName)
        _savedBomsClassName  = State(initialValue: s.bomFolderClassName)
        _savedBomsType       = State(initialValue: s.bomFolderType)

        _savedRequirementsName      = State(initialValue: s.reqSpecFolderName)
        _savedRequirementsClassName = State(initialValue: s.reqSpecFolderClassName)
        _savedRequirementsType      = State(initialValue: s.reqSpecFolderType)
    }

    // MARK: - View ----------------------------------------------------------
    public var body: some View {
        HStack(spacing: 20) {
            // Column 1: Items -----------------------------------------------
            makeColumn(title: "Items", selection: $selectedItemsUid, savedName: savedItemsName) { newUid in
                onSelect(newUid: newUid,
                         savedName: &savedItemsName, savedClassName: &savedItemsClassName, savedType: &savedItemsType,
                         uidKeyPath: \.itemsFolderUid,
                         nameKeyPath: \.itemsFolderName,
                         classKeyPath: \.itemsFolderClassName,
                         typeKeyPath: \.itemsFolderType)
            }
            // Column 2: BOMs -----------------------------------------------
            makeColumn(title: "BOM's", selection: $selectedBomsUid, savedName: savedBomsName) { newUid in
                onSelect(newUid: newUid,
                         savedName: &savedBomsName, savedClassName: &savedBomsClassName, savedType: &savedBomsType,
                         uidKeyPath: \.bomFolderUid,
                         nameKeyPath: \.bomFolderName,
                         classKeyPath: \.bomFolderClassName,
                         typeKeyPath: \.bomFolderType)
            }
            // Column 3: Requirements ---------------------------------------
            makeColumn(title: "Requirements", selection: $selectedRequirementsUid, savedName: savedRequirementsName) { newUid in
                onSelect(newUid: newUid,
                         savedName: &savedRequirementsName, savedClassName: &savedRequirementsClassName, savedType: &savedRequirementsType,
                         uidKeyPath: \.reqSpecFolderUid,
                         nameKeyPath: \.reqSpecFolderName,
                         classKeyPath: \.reqSpecFolderClassName,
                         typeKeyPath: \.reqSpecFolderType)
            }
        }
        .padding()
        .onAppear(perform: validateSelections)    // Clean up stale selections
        .onChange(of: folders) {
            validateSelections()
        }  // Re‑validate when new data arrives
    }

    // MARK: - Column builder ------------------------------------------------
    /// Builds a *single* column (title + picker) for Items, BOMs or Requirements.
    private func makeColumn(title: String, selection: Binding<String>, savedName: String, onChange: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Picker("", selection: selection) {
                // 1) Show live folders
                if !folders.isEmpty {
                    ForEach(folders) { f in Text(f.name).tag(f.id) }
                    // 2) If the saved UID is missing from list, show it anyway so user can clear it.
                    if !savedName.isEmpty && !folders.contains(where: { $0.id == selection.wrappedValue }) {
                        Text(savedName).tag(selection.wrappedValue)
                    }
                } else if !savedName.isEmpty {
                    // No folders yet, but we still show the saved value
                    Text(savedName).tag(selection.wrappedValue)
                }
            }
            .pickerStyle(PopUpButtonPickerStyle())
            .onChange(of: selection.wrappedValue) { _, newValue in onChange(newValue) }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Unified selection handler ------------------------------------
    /// Stores the new UID (or clears it) in SettingsManager and updates local @State copies.
    private func onSelect(newUid: String,
                          savedName: inout String, savedClassName: inout String, savedType: inout String,
                          uidKeyPath: ReferenceWritableKeyPath<SettingsManager, String>,
                          nameKeyPath: ReferenceWritableKeyPath<SettingsManager, String>,
                          classKeyPath: ReferenceWritableKeyPath<SettingsManager, String>,
                          typeKeyPath: ReferenceWritableKeyPath<SettingsManager, String>) {
        let s = SettingsManager.shared
        s[keyPath: uidKeyPath] = newUid
        if let folder = folders.first(where: { $0.id == newUid }) {
            // Save full metadata when UID exists
            s[keyPath: nameKeyPath]  = folder.name
            s[keyPath: classKeyPath] = folder.className
            s[keyPath: typeKeyPath]  = folder.type
            savedName      = folder.name
            savedClassName = folder.className
            savedType      = folder.type
        } else {
            // Clear when UID is empty or invalid
            s[keyPath: nameKeyPath]  = ""
            s[keyPath: classKeyPath] = ""
            s[keyPath: typeKeyPath]  = ""
            savedName = ""; savedClassName = ""; savedType = ""
        }
    }

    // MARK: - Helpers -------------------------------------------------------
    /// If a previously saved UID is no longer present in `folders`, delete it.
    private func validateSelections() {
        guard !folders.isEmpty else { return }
        let s = SettingsManager.shared

        if !folders.contains(where: { $0.id == selectedItemsUid }) {
            s.itemsFolderUid = ""; s.itemsFolderName = ""; s.itemsFolderClassName = ""; s.itemsFolderType = ""
            selectedItemsUid = ""; savedItemsName = ""; savedItemsClassName = ""; savedItemsType = ""
        }
        if !folders.contains(where: { $0.id == selectedBomsUid }) {
            s.bomFolderUid = ""; s.bomFolderName = ""; s.bomFolderClassName = ""; s.bomFolderType = ""
            selectedBomsUid = ""; savedBomsName = ""; savedBomsClassName = ""; savedBomsType = ""
        }
        if !folders.contains(where: { $0.id == selectedRequirementsUid }) {
            s.reqSpecFolderUid = ""; s.reqSpecFolderName = ""; s.reqSpecFolderClassName = ""; s.reqSpecFolderType = ""
            selectedRequirementsUid = ""; savedRequirementsName = ""; savedRequirementsClassName = ""; savedRequirementsType = ""
        }
    }
}

// Simple data holder for each folder row coming from the backend.
struct FolderItem: Identifiable, Equatable {
    let id: String       // Teamcenter UID
    let name: String     // Display name
    let className: String// Should be "Folder"
    let type: String     // Folder subtype
}

