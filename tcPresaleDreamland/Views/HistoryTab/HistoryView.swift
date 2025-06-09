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
    @State private var selectedItem: GeneratedItemsDataByLLM.ID?
    
    init () {
        _vm = StateObject(wrappedValue: HistoryViewModel())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    DisclosureGroup(
                                   isExpanded: $vm.isItemsHistorySectionExpanded
                               ) {
                                   Table(vm.itemsHistory, selection: $selectedItem) {
                                       // Name column
                                       TableColumn("Name") { item in
                                           Text(item.name!)            // name is non-optional on StoredItem
                                                               }
                                       // Timestamp column
                                       TableColumn("Date") { item in
                                           Text(item.timestamp!, formatter: dateFormatter)
                                                               }
                                   }
                                   .frame(minHeight: 200)
                               } label: {
                                   SectionHeader(
                                       title: "Items Generated History",
                                       systemImage: "list.bullet",
                                       isExpanded: vm.isItemsHistorySectionExpanded
                                   )
                               }

                    // MARK: BOM's Generated History
                    DisclosureGroup(
                        isExpanded: $vm.isBOMsHistorySectionExpanded
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            // TODO: ForEach(vm.bomsHistory) { … }
                            Text("Coming soon.")
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(8)
                    } label: {
                        SectionHeader(
                            title: "BOM's Generated History",
                            systemImage: "list.bullet",
                            isExpanded: vm.isBOMsHistorySectionExpanded
                        )
                    }

                    // MARK: Requirement Specs Generated History
                    DisclosureGroup(
                        isExpanded: $vm.isReqSpecHistorySectionExpanded
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            // TODO: ForEach(vm.reqSpecsHistory) { … }
                            Text("Coming soon.")
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(8)
                    } label: {
                        SectionHeader(
                            title: "Requirement Specifications Generated History",
                            systemImage: "list.bullet",
                            isExpanded: vm.isReqSpecHistorySectionExpanded
                        )
                    }
                }
                .animation(.default, value: vm.isItemsHistorySectionExpanded)
                .animation(.default, value: vm.isBOMsHistorySectionExpanded)
                .animation(.default, value: vm.isReqSpecHistorySectionExpanded)
                .padding(.vertical, 8)
            }
        }
        .padding(20)
    }

    // DateFormatter for consistency
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }

    // MARK: Section Header
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
