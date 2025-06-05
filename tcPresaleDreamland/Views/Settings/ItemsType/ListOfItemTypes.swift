//
//  ListOfItemTypes.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 05/06/2025.
//

import SwiftUI

struct ListEditorView: View {
    @Binding var items: [String]
    @State private var newItemName: String = ""
    @State private var selectedItem: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            // The List of plain strings
            List(selection: $selectedItem) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .tag(item)
                }
            }
            .frame(minHeight: 200)
            .border(Color.gray.opacity(0.5))

            Divider()

            // TextField + buttons to add/remove
            HStack {
                TextField("New INTERNAL Object Name only", text: $newItemName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 200)

                Button(action: addItem) {
                    Image(systemName: "plus")
                }
               // .help("Add the text above to the list")

                Button(action: deleteItem) {
                    Image(systemName: "minus")
                }
                .disabled(selectedItem == nil || selectedItem == "Item")
                //.help("Remove the selected item (except “Item” itself)")
            }
            .padding(8)
        }
        .padding(8)
    }

    private func addItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        items.append(trimmed)
        newItemName = ""
        selectedItem = nil
    }

    private func deleteItem() {
        guard let toDelete = selectedItem,
              let index = items.firstIndex(of: toDelete)
        else { return }
        items.remove(at: index)
        selectedItem = nil
    }
}
