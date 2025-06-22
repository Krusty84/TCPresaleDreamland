//
//  ExampleView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import SwiftUI

struct ItemsGeneratorContent: View {
    @ObservedObject var vm: ItemsGeneratorViewModel  // Injected view‑model
    @State private var selectAll = false            // Not used (just kept)
    @State private var headerType = ""              // For future header‑picker

    // Helper that returns a *Binding* to a property of an `Item` in the list.
    private func binding<T>(
        for item: Item,
        keyPath: WritableKeyPath<Item, T>
    ) -> Binding<T> {
        Binding(
            get: { item[keyPath: keyPath] },
            set: { newValue in
                if let index = vm.generatedItems.firstIndex(where: { $0.id == item.id }) {
                    vm.generatedItems[index][keyPath: keyPath] = newValue
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CallLLMView(
                domainName:   $vm.domainName,
                countText:    $vm.count,
                temperature:  $vm.itemsTemperature,
                maxTokens:    $vm.itemsMaxTokens,
                isLoading:    vm.isLoading,
                generateAction: vm.generateItems,
                generateButtonLabel: "Generate Items",
                generateButtonHelp: "Ask DeepSeek to generate a list of items"
            ) .padding()

            Divider()

            // ---------- 2) Table + loading overlay ----------
            ZStack {
                // (a) Table
                Table(vm.generatedItems) {
                    // Checkbox column -------------------------
                    TableColumn("") { item in
                        Toggle("", isOn: binding(for: item, keyPath: \.isEnabled))
                            .toggleStyle(CheckboxToggleStyle())
                            .contextMenu {
                                Button("Select All") {
                                    for i in vm.generatedItems.indices { vm.generatedItems[i].isEnabled = true }
                                }
                                Button("Deselect All") {
                                    for i in vm.generatedItems.indices { vm.generatedItems[i].isEnabled = false }
                                }
                            }
                    }
                    .width(20)

                    // Name column -----------------------------
                    TableColumn("Name") { item in
                        Text(item.name).font(.headline)
                    }
                    .width(min: 100, max: 200)

                    // Description column ----------------------
                    TableColumn("Description") { item in
                        Text(item.desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .width(min: 100, max: 300)

                    // Type column (picker) --------------------
                    TableColumn("Type") { item in
                        Picker("", selection: binding(for: item, keyPath: \.type)) {
                            ForEach(vm.itemTypes, id: \.self) { type in Text(type).tag(type) }
                        }
                        .help("Type of object that will be created in Teamcenter")
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                        .labelsHidden()
                        .contextMenu {
                            Button("Apply to All") {
                                let chosenType = item.type
                                for i in vm.generatedItems.indices { vm.generatedItems[i].type = chosenType }
                            }
                        }
                    }
                    .width(120)
                }

                // (b) Loading overlay ------------------------
                if vm.isLoading {
                    Color.black.opacity(0.25) // Dim background
                        .edgesIgnoringSafeArea(.all)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                }
            }

            // ---------- 3) Bottom action view ----------
            PushToTCView(
                uid: vm.containerFolderUid,
                containerFolderName: vm.domainName,
                pushToHistoryAction: {
                    await vm.saveGeneratedItemsToHistory()
                },
                pushToTCVoidAction: {
                    let report = await vm.createSelectedItems()
                    let failures = report.filter { !$0.success }.map(\.itemName)
                    if !failures.isEmpty {
                        // TODO: Show alert with failures.
                    }
                }
            )
            .disabled(vm.generatedItems.allSatisfy { !$0.isEnabled })
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}


#if DEBUG
//struct ItemsGeneratorContent_Previews: PreviewProvider {
//    static var previews: some View {
//        ItemsGeneratorContent()
//    }
//}
#endif
