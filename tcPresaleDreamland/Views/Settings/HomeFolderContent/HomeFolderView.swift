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
    let className: String
    let type: String
}

public struct HomeFolderContent: View {
    // 1) Raw JSON data passed in
    private let rawData: [[String: Any]]
    
    // Selected UIDs
    @State private var selectedItemsUid: String
    @State private var selectedBomsUid: String
    @State private var selectedRequirementsUid: String
    
    // Saved metadata (name, className, type)
    @State private var savedItemsName: String
    @State private var savedItemsClassName: String
    @State private var savedItemsType: String
    
    @State private var savedBomsName: String
    @State private var savedBomsClassName: String
    @State private var savedBomsType: String
    
    @State private var savedRequirementsName: String
    @State private var savedRequirementsClassName: String
    @State private var savedRequirementsType: String
    
    // 5) Only keep items where className == "Folder"
    private var folders: [FolderItem] {
        rawData.compactMap { dict in
            guard
                let className = dict["className"] as? String,
                className == "Folder",
                let uid = dict["uid"] as? String,
                let name = dict["object_name"] as? String,
                let type = dict["type"] as? String
            else { return nil }
            return FolderItem(id: uid, name: name, className: className, type: type)
        }
    }
    
    // MARK: - Initializer
    public init(rawData: [[String: Any]]) {
        self.rawData = rawData
        
        // load saved UIDs
        let itemsUid  = SettingsManager.shared.itemsFolderUid
        let bomsUid   = SettingsManager.shared.bomsFolderUid
        let reqUid    = SettingsManager.shared.requirementsFolderUid
        
        // load saved names, classNames, types
        let itemsName      = SettingsManager.shared.itemsFolderName
        let itemsClassName = SettingsManager.shared.itemsFolderClassName
        let itemsType      = SettingsManager.shared.itemsFolderType
        
        let bomsName      = SettingsManager.shared.bomsFolderName
        let bomsClassName = SettingsManager.shared.bomsFolderClassName
        let bomsType      = SettingsManager.shared.bomsFolderType
        
        let reqName      = SettingsManager.shared.requirementsFolderName
        let reqClassName = SettingsManager.shared.requirementsFolderClassName
        let reqType      = SettingsManager.shared.requirementsFolderType
        
        // initialize @State
        _selectedItemsUid         = State(initialValue: itemsUid)
        _selectedBomsUid          = State(initialValue: bomsUid)
        _selectedRequirementsUid  = State(initialValue: reqUid)
        
        _savedItemsName           = State(initialValue: itemsName)
        _savedItemsClassName      = State(initialValue: itemsClassName)
        _savedItemsType           = State(initialValue: itemsType)
        
        _savedBomsName            = State(initialValue: bomsName)
        _savedBomsClassName       = State(initialValue: bomsClassName)
        _savedBomsType            = State(initialValue: bomsType)
        
        _savedRequirementsName    = State(initialValue: reqName)
        _savedRequirementsClassName = State(initialValue: reqClassName)
        _savedRequirementsType      = State(initialValue: reqType)
    }
    
    public var body: some View {
        HStack(spacing: 20) {
            makeColumn(
                title: "Items",
                selection: $selectedItemsUid,
                savedName: savedItemsName
            ) { newUid in
                onSelect(
                    newUid: newUid,
                    savedName: &savedItemsName,
                    savedClassName: &savedItemsClassName,
                    savedType: &savedItemsType,
                    uidKeyPath: \.itemsFolderUid,
                    nameKeyPath: \.itemsFolderName,
                    classKeyPath: \.itemsFolderClassName,
                    typeKeyPath: \.itemsFolderType
                )
            }
            
            makeColumn(
                title: "BOM's",
                selection: $selectedBomsUid,
                savedName: savedBomsName
            ) { newUid in
                onSelect(
                    newUid: newUid,
                    savedName: &savedBomsName,
                    savedClassName: &savedBomsClassName,
                    savedType: &savedBomsType,
                    uidKeyPath: \.bomsFolderUid,
                    nameKeyPath: \.bomsFolderName,
                    classKeyPath: \.bomsFolderClassName,
                    typeKeyPath: \.bomsFolderType
                )
            }
            
            makeColumn(
                title: "Requirements",
                selection: $selectedRequirementsUid,
                savedName: savedRequirementsName
            ) { newUid in
                onSelect(
                    newUid: newUid,
                    savedName: &savedRequirementsName,
                    savedClassName: &savedRequirementsClassName,
                    savedType: &savedRequirementsType,
                    uidKeyPath: \.requirementsFolderUid,
                    nameKeyPath: \.requirementsFolderName,
                    classKeyPath: \.requirementsFolderClassName,
                    typeKeyPath: \.requirementsFolderType
                )
            }
        }
        .padding()
        .onAppear(perform: validateSelections)
        .onChange(of: folders) { _ in validateSelections() }
    }
    
    // Builds each VStack + Picker
    private func makeColumn(title: String,
                            selection: Binding<String>,
                            savedName: String,
                            onChange: @escaping (String) -> Void) -> some View
    {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Picker("", selection: selection) {
                if !folders.isEmpty {
                    ForEach(folders) { f in Text(f.name).tag(f.id) }
                    if !savedName.isEmpty && !folders.contains(where: { $0.id == selection.wrappedValue }) {
                        Text(savedName).tag(selection.wrappedValue)
                    }
                } else if !savedName.isEmpty {
                    Text(savedName).tag(selection.wrappedValue)
                }
            }
            .pickerStyle(PopUpButtonPickerStyle())
            .onChange(of: selection.wrappedValue, perform: onChange)
        }
        .frame(maxWidth: .infinity)
    }
    
    // Unified selection handler
    private func onSelect(
        newUid: String,
        savedName: inout String,
        savedClassName: inout String,
        savedType: inout String,
        uidKeyPath: ReferenceWritableKeyPath<SettingsManager, String>,
        nameKeyPath: ReferenceWritableKeyPath<SettingsManager, String>,
        classKeyPath: ReferenceWritableKeyPath<SettingsManager, String>,
        typeKeyPath: ReferenceWritableKeyPath<SettingsManager, String>
    ) {
        let settings = SettingsManager.shared
        settings[keyPath: uidKeyPath] = newUid
        
        if let folder = folders.first(where: { $0.id == newUid }) {
            settings[keyPath: nameKeyPath]      = folder.name
            settings[keyPath: classKeyPath]     = folder.className
            settings[keyPath: typeKeyPath]      = folder.type
            
            savedName       = folder.name
            savedClassName  = folder.className
            savedType       = folder.type
        } else {
            // clear if none
            settings[keyPath: nameKeyPath]      = ""
            settings[keyPath: classKeyPath]     = ""
            settings[keyPath: typeKeyPath]      = ""
            
            savedName       = ""
            savedClassName  = ""
            savedType       = ""
        }
    }
    
    private func validateSelections() {
        guard !folders.isEmpty else { return }
        let settings = SettingsManager.shared
        
        if !folders.contains(where: { $0.id == selectedItemsUid }) {
            settings.itemsFolderUid = ""
            settings.itemsFolderName = ""
            settings.itemsFolderClassName = ""
            settings.itemsFolderType = ""
            selectedItemsUid = ""
            savedItemsName = ""
            savedItemsClassName = ""
            savedItemsType = ""
        }
        if !folders.contains(where: { $0.id == selectedBomsUid }) {
            settings.bomsFolderUid = ""
            settings.bomsFolderName = ""
            settings.bomsFolderClassName = ""
            settings.bomsFolderType = ""
            selectedBomsUid = ""
            savedBomsName = ""
            savedBomsClassName = ""
            savedBomsType = ""
        }
        if !folders.contains(where: { $0.id == selectedRequirementsUid }) {
            settings.requirementsFolderUid = ""
            settings.requirementsFolderName = ""
            settings.requirementsFolderClassName = ""
            settings.requirementsFolderType = ""
            selectedRequirementsUid = ""
            savedRequirementsName = ""
            savedRequirementsClassName = ""
            savedRequirementsType = ""
        }
    }
}

