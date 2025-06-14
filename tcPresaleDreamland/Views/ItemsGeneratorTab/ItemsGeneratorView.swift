//
//  ExampleView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import SwiftUI

struct ItemsGeneratorContent: View {
    @ObservedObject var vm: ItemsGeneratorViewModel
    @State private var selectAll = false
    @State private var headerType = "" // used only for the header‐picker
    
    // Helper function to create bindings
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
                // Top controls
                HStack {
                    TextField("Domain", text: $vm.domainName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                        .help("Product (for example: airplane, transmitter, neutron accelerator, etc.) or industry (for example: nuclear, chemical, etc)")
    
                    HStack(spacing: 4) {
                        Text("Count:")
                        Stepper(
                            value: Binding(
                                get: { Int(vm.count) ?? 10 },
                                set: { vm.count = "\($0)" }
                            ),
                            in: 1...1000,
                            step: 1
                        ) {
                            Text("\(Int(vm.count) ?? 10)")
                                .monospacedDigit()
                                .frame(width: 60)
                        }
                    }
                    .help("Expected number of generated items")
                    .frame(width: 140)
    
                    HStack(spacing: 4) {
                        Text("Temperature:")
                        Stepper(value: $vm.itemsTemperature, in: 0...1, step: 0.1) {
                            Text("\(vm.itemsTemperature, specifier: "%.1f")")
                                .monospacedDigit()
                                .frame(width: 40)
                        }
                    }
                    .help("Creativity level: the higher the value, the more creative it is, but it might be far from reality")
                    .frame(width: 200)
    
                    HStack(spacing: 4) {
                        Text("Tokens:")
                        Stepper(value: $vm.itemsMaxTokens, in: 100...4000, step: 100) {
                            Text("\(vm.itemsMaxTokens)")
                                .monospacedDigit()
                                .frame(width: 50)
                        }
                    }
                    .help("The maximum number of tokens that can be generated")
                    .frame(width: 160)
    
                    Button("Generate Items") {
                        vm.generateItems()
                    }
                    .help("Generate Items")
                    .disabled(vm.isLoading || vm.domainName.isEmpty)
                }
                .padding()
    
                Divider()
    
                // Table wrapped in a ZStack so we can overlay the loading spinner
                ZStack {
                    // 1) The actual table of items
                    Table(vm.generatedItems) {
                        // 1) First column: checkbox + contextMenu on each row’s cell
                        TableColumn("") { item in
                            Toggle("", isOn: binding(for: item, keyPath: \.isEnabled))
                                .toggleStyle(CheckboxToggleStyle())
                                .contextMenu {
                                    Button("Select All") {
                                        for i in vm.generatedItems.indices {
                                            vm.generatedItems[i].isEnabled = true
                                        }
                                    }
                                    Button("Deselect All") {
                                        for i in vm.generatedItems.indices {
                                            vm.generatedItems[i].isEnabled = false
                                        }
                                    }
                                }
                        }
                        .width(20)
    
                        // 2) Name column (display only)
                        TableColumn("Name") { item in
                            Text(item.name)
                                .font(.headline)
                        }
                        .width(min: 100, max: 200)
    
                        // 3) Description column (display only)
                        TableColumn("Description") { item in
                            Text(item.desc)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .width(min: 100, max: 300)
    
                        // 4) Type column: picker + contextMenu on each row’s picker
                        TableColumn("Type") { item in
                            Picker("", selection: binding(for: item, keyPath: \.type)) {
                                ForEach(vm.itemTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .help("Type of object that will be created in Teamcenter")
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 120)
                            .labelsHidden()
                            .contextMenu {
                                Button("Apply to All") {
                                    let chosenType = item.type
                                    for i in vm.generatedItems.indices {
                                        vm.generatedItems[i].type = chosenType
                                    }
                                }
                            }
                        }
                        .width(120)
                    }
    
                    // 2) If vm.isLoading is true, overlay a semi-transparent layer + spinner
                    if vm.isLoading {
                        // Semi-transparent background to dim the table
                        Color.black.opacity(0.25)
                            .edgesIgnoringSafeArea(.all)
    
                        // Centered ProgressView without a background
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5) // make it a bit larger if you like
                    }
                }
    
                PushToTCView(
                    uid: vm.containerFolderUid,
                    containerFolderName: vm.domainName,
                    pushToHistoryAction: {
                        await vm.saveGeneratedItemsToHistory()
                    },
                    pushToTCVoidAction: {
                        let report = await vm.createSelectedItems()
                        let failures = report
                            .filter { !$0.success }
                            .map(\.itemName)
    
                        if !failures.isEmpty {
                            // all good
                        }
                    }
                ).disabled(vm.generatedItems.allSatisfy { !$0.isEnabled })
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
