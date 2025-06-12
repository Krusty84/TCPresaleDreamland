//
//  HistoryView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 08/06/2025.
//

import SwiftUI
import CoreData

struct HistoryContent: View {
    @StateObject private var vm = HistoryViewModel()
    @ObservedObject var vmItemsGeneratorViewModel: ItemsGeneratorViewModel
    @State private var selectedItemsHistoryRow: GeneratedItemsDataByLLM.ID? = nil
   
    @State private var itemsExpanded = true
    @State private var bomsExpanded = false
    @State private var specsExpanded = false
    
    @FocusState private var itemsTableIsFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            itemsHistorySection
            bomsHistorySection.disabled(true)
            specsHistorySection.disabled(true)
            Spacer()
        }
        .padding(20)
        .environmentObject(vmItemsGeneratorViewModel)
    }

    // MARK: Items Generated History

    private var itemsHistorySection: some View {
        DisclosureGroup(
            isExpanded: $itemsExpanded,
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
                    isExpanded: itemsExpanded
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
                    vm.restore(selectedRowId: [selectedID], itemsGeneratorViewModel: vmItemsGeneratorViewModel)
                }
            }
            .disabled(selectedItemsHistoryRow == nil)
            Spacer()
            Button("Delete") {
                if let selectedID = selectedItemsHistoryRow {
                    vm.delete(selectedRowId: [selectedID])
                }
            }.disabled(selectedItemsHistoryRow == nil)
            .foregroundColor(.red)
        }
        .padding(.top, 8)
    }

    // MARK: BOM Generated History

    private var bomsHistorySection: some View {
        DisclosureGroup(
            isExpanded: $bomsExpanded,
            content: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Coming soon.")
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(8)
            },
            label: {
                SectionHeader(
                    title: "BOM's Generated History",
                    systemImage: "list.bullet",
                    isExpanded: bomsExpanded
                )
            }
        )
    }
  
    // MARK: Req Spec Generated History
    
    private var specsHistorySection: some View {
        DisclosureGroup(
            isExpanded: $specsExpanded,
            content: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Coming soon.")
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(8)
            },
            label: {
                SectionHeader(
                    title: "Requirement Specs Generated History",
                    systemImage: "list.bullet",
                    isExpanded: specsExpanded
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
