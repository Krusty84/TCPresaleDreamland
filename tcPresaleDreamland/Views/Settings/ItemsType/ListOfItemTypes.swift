//
//  ListOfItemTypes.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 05/06/2025.
//

import SwiftUI

struct ListEditorView: View {
    // Binding to the array that lives outside (usually in SettingsManager)
    @Binding var items: [String]

    // Local state for the TextField and List selection
    @State private var newItemName: String = ""  // What user types
    @State private var selectedItem: String? = nil // Selected row (nil = none)

    var body: some View {
        VStack(spacing: 0) {
            // -------------------------------------------- List of items
            List(selection: $selectedItem) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .tag(item)   // Tag so List knows row identity
                }
            }
            .frame(minHeight: 200)
            .border(Color.gray.opacity(0.5))

            Divider() // Thin line between list and controls

            // -------------------------------------- TextField + buttons row
            HStack {
                // Where the user types a new string
                TextField("INTERNAL Object Name only", text: $newItemName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 200)

                // + button → add to list
                Button(action: addNewType) {
                    Image(systemName: "plus")
                }

                // – button → remove selected (disabled when no row is chosen or default "Item")
                Button(action: deleteType) {
                    Image(systemName: "minus")
                }
                .disabled(selectedItem == nil || selectedItem == "Item")
            }
            .padding(8)
        }
        .padding(8)
    }

    // MARK: - Private helpers ----------------------------------------------
    /// Append the trimmed string to `items`, then clear UI state.
    private func addNewType() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        items.append(trimmed)
        newItemName = ""
        selectedItem = nil
    }

    /// Remove the selected string from `items`, then clear selection.
    private func deleteType() {
        guard let toDelete = selectedItem,
              let index    = items.firstIndex(of: toDelete) else { return }
        items.remove(at: index)
        selectedItem = nil
    }
}
