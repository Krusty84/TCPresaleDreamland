//
//  HistoryView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 08/06/2025.
//

import SwiftUI
import CoreData
import AppKit
import UniformTypeIdentifiers

struct HistoryContent: View {
    @StateObject private var vm = HistoryViewModel()
    @ObservedObject var vmItemsGeneratorViewModel: ItemsGeneratorViewModel
    @ObservedObject var vmBOMGeneratorViewModel: BomGeneratorViewModel
    @State private var selectedItemsHistoryRow: GeneratedItemsDataByLLM.ID? = nil
    @State private var selectedBOMsHistoryRow: GeneratedBOMDataByLLM.ID? = nil
        
    private enum Section { case items, boms, reqspec, none }
    @State private var expandedSection: Section = .items
    
    @FocusState private var itemsTableIsFocused: Bool
    @FocusState private var bomsTableIsFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            itemsHistorySection
            bomsHistorySection
            reqSpecsHistorySection.disabled(true)
            Spacer()
        }
        .padding(20)
        //.environmentObject(vmItemsGeneratorViewModel)
    }
    
    // MARK: Items Generated History
    private var itemsHistorySection: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedSection == .items },
                set: { isOn in
                    expandedSection = isOn ? .items : .none
                }
            ),
            content: {
                VStack(spacing: 16) {
                    itemsTable
                    itemsButtons
                }
                .padding(12)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(8)
            },
            label: {
                SectionHeader(
                    title: "Items Generated History",
                    systemImage: "list.bullet",
                    isExpanded: expandedSection == .items
                )
            }
        )
    }
    
    // 1) break out the Table into its own var
    private var itemsTable: some View {
        Table(vm.itemsHistory, selection: $selectedItemsHistoryRow) {
            TableColumn("Name") { row in
                Text(row.name ?? "–")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            TableColumn("Date") { row in
                if let date = row.timestamp {
                    Text(date, formatter: vm.dateFormatter)
                } else {
                    Text("N/A")
                }
            }
        }
        .frame(minHeight: 200)
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .alternatingRowBackgrounds(.enabled)
        .scrollContentBackground(.hidden)
        .accentColor(Color(nsColor: .selectedControlColor))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .focused($itemsTableIsFocused)
        .onAppear {
            DispatchQueue.main.async {
                itemsTableIsFocused = true
            }
        }
    }
    private var itemsButtons: some View {
        HStack {
            Button("Restore") {
                if let selectedID = selectedItemsHistoryRow {
                    vm.restoreItemHistory(selectedRowId: [selectedID], itemsGeneratorViewModel: vmItemsGeneratorViewModel)
                }
            }
            .disabled(selectedItemsHistoryRow == nil)
            Spacer()
            
            Button("Import Items List") {
                Task { @MainActor in
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.json]
                    panel.canChooseDirectories = false
                    panel.allowsMultipleSelection = false
                    
                    guard panel.runModal() == .OK,
                          let url = panel.url,
                          let data = try? Data(contentsOf: url)
                    else { return }
                    
                    do {
                        let pkg = try JSONDecoder()
                            .decode(HistoryViewModel.ImportItemsPackage.self, from: data)
                        vm.importItemsDataFromJSONFile(pkg)
                    } catch {
                        print("❌ Failed to decode import JSON:", error)
                    }
                }
            }
            
            Button("Export Items List") {
                Task { @MainActor in
                    guard let id = selectedItemsHistoryRow,
                          let jsonData = vm.exportItemsDataToJSONFile(selectedRowId: [id])
                    else { return }
                    
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.json]
                    let batch = vm.itemsHistory.first { $0.id == id }
                    let defaultName = batch?.name ?? "export"
                    panel.nameFieldStringValue = "\(defaultName)_items.json"
                    
                    if panel.runModal() == .OK, let url = panel.url {
                        do {
                            try jsonData.write(to: url)
                        } catch {
                            print("❌ Write error:", error)
                        }
                    }
                }
            }
            .disabled(selectedItemsHistoryRow == nil)
            
            //Spacer()
            Button("Delete") {
                if let selectedID = selectedItemsHistoryRow {
                    vm.deleteItemHistory(selectedRowId: [selectedID])
                }
            }.disabled(selectedItemsHistoryRow == nil)
                .foregroundColor(.red)
        }
        .padding(.top, 8)
    }
    
    // MARK: BOM Generated History
    private var bomsHistorySection: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedSection == .boms },
                set: { isOn in
                    expandedSection = isOn ? .boms : .none
                }
            ),
            content: {
                VStack(spacing: 16) {
                    bomsTable
                    bomsButtons
                }
                .padding(12)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(8)
            },
            label: {
                SectionHeader(
                    title: "BOM’s Generated History",
                    systemImage: "list.bullet",
                    isExpanded: expandedSection == .boms
                )
            }
        )
    }
    
    private var bomsTable: some View {
        Table(vm.bomsHistory, selection: $selectedBOMsHistoryRow) {
            TableColumn("Name") { row in
                Text(row.name ?? "–")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            TableColumn("Date") { row in
                if let date = row.timestamp {
                    Text(date, formatter: vm.dateFormatter)
                } else {
                    Text("N/A")
                }
            }
        }
        .frame(minHeight: 200)
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .alternatingRowBackgrounds(.enabled)
        .scrollContentBackground(.hidden)
        .accentColor(Color(nsColor: .selectedControlColor))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .focused($bomsTableIsFocused)
        .onAppear {
            DispatchQueue.main.async {
                bomsTableIsFocused = true
            }
        }
    }
    
    private var bomsButtons: some View {
        HStack {
            Button("Restore") {
                if let selectedID = selectedBOMsHistoryRow {
                    vm.restoreBOMHistory(selectedRowIds: [selectedID], bomGeneratorViewModel: vmBOMGeneratorViewModel)
                }
            }
            .disabled(selectedBOMsHistoryRow == nil)
            Spacer()
            
            Button("Import BOM") {
                Task { @MainActor in
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.json]
                    panel.canChooseDirectories = false
                    panel.allowsMultipleSelection = false
                    
                    guard panel.runModal() == .OK,
                          let url = panel.url,
                          let data = try? Data(contentsOf: url)
                    else { return }
                    
                    do {
                        let pkg = try JSONDecoder()
                            .decode(HistoryViewModel.ImportBOMPackage.self, from: data)
                        vm.importBOMDataFromJSONFile(pkg)
                    } catch {
                        print("❌ Failed to decode import JSON:", error)
                    }
                }
            }
            
            Button("Export BOM") {
                Task { @MainActor in
                    guard let id = selectedBOMsHistoryRow,
                          let jsonData = vm.exportBOMDataToJSONFile(selectedRowId: [id])
                    else { return }
                    
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.json]
                    let batch = vm.bomsHistory.first { $0.id == id }
                    let defaultName = batch?.name ?? "export"
                    panel.nameFieldStringValue = "\(defaultName)_bom.json"
                    
                    if panel.runModal() == .OK, let url = panel.url {
                        do {
                            try jsonData.write(to: url)
                        } catch {
                            print("❌ Write error:", error)
                        }
                    }
                }
            }
            .disabled(selectedBOMsHistoryRow == nil)
            
            //Spacer()
            Button("Delete") {
                if let selectedID = selectedBOMsHistoryRow {
                    vm.deleteBOMHistory(selectedRowId: [selectedID])
                }
            }.disabled(selectedBOMsHistoryRow == nil)
                .foregroundColor(.red)
        }
        .padding(.top, 8)
    }
    
    // MARK: Req Spec Generated History
    
    private var reqSpecsHistorySection: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedSection == .reqspec },
                set: { isOn in
                    expandedSection = isOn ? .boms : .none
                }
            ),
            content: {
                VStack(spacing: 16) {
                    //bomsTable
                    //bomsButtons
                }
                .padding(12)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(8)
            },
            label: {
                SectionHeader(
                    title: "Req Spec Generated History",
                    systemImage: "list.bullet",
                    isExpanded: expandedSection == .reqspec
                )
            }
        )
    }
    
    struct SectionHeader: View {
        let title: String
        let systemImage: String
        var isExpanded: Bool
        
        var body: some View {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                Spacer()
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .contentShape(Rectangle())
        }
    }
}


#if DEBUG
//struct HistoryContent_Previews: PreviewProvider {
//    static var previews: some View {
//        HistoryContent()
//    }
//}
#endif
