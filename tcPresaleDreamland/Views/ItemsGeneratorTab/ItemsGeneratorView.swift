//
//  ExampleView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import SwiftUI

struct ItemsGeneratorContent: View {
    @ObservedObject var vm: ItemsGeneratorViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top controls (left-aligned)
            HStack {
                TextField("Domain", text: $vm.domainName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                HStack(spacing: 4) {
                    Text("Count:")
                    Stepper(
                        value: Binding(
                            get: { Int(vm.count) ?? 10 },  // Convert String → Int (default to 1 if invalid)
                            set: { vm.count = "\($0)" }   // Convert Int → String
                        ),
                        in: 1...1000,  // Adjust range as needed
                        step: 1
                    ) {
                        Text("\(Int(vm.count) ?? 10)")  // Display current value
                            .monospacedDigit()
                            .frame(width: 60)
                    }
                }
                .frame(width: 140)  // Adjust width to fit your layout
                
                HStack(spacing: 4) {
                    Text("Temp:")
                    Stepper(value: $vm.itemsTemperature, in: 0...1, step: 0.1) {
                        Text("\(vm.itemsTemperature, specifier: "%.1f")")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                }
                .frame(width: 140)
                
                // Max Tokens Stepper
                HStack(spacing: 4) {
                    Text("Tokens:")
                    Stepper(value:$vm.itemsMaxTokens, in: 100...4000, step: 100) {
                        Text("\(vm.itemsMaxTokens)")
                            .monospacedDigit()
                            .frame(width: 50)
                    }
                }
                .frame(width: 160)
                
                Button("Generate Items") {
                    vm.generateItems()
                }
                .disabled(vm.isLoading || vm.domainName.isEmpty )
            }
            .padding()
            
            Divider()
            
            // Content area
//            ZStack {
//                List(vm.generatedItems, id: \.name) { item in
//                    VStack(alignment: .leading) {
//                        Text(item.name).font(.headline)
//                        Text(item.desc).foregroundColor(.secondary)
//                        Text(item.type).foregroundColor(.secondary)
//                    }
//                }
//                
//                if vm.isLoading {
//                    ProgressView()
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                }
//                
//                if let errorMessage = vm.errorMessage {
//                    Text(errorMessage)
//                        .foregroundColor(.red)
//                }
//            }
            
            List {
                // Iterate over bindings so that each row can update the item in-place:
                ForEach($vm.generatedItems) { $item in
                    HStack(spacing: 12) {
                        // 1) A checkbox (no label). Bind it to item.isEnabled:
                        Toggle("", isOn: $item.isEnabled)
                            .toggleStyle(CheckboxToggleStyle())
                            .frame(width: 20) // make checkbox column narrow

                        // 2) A VStack for Name ↑ and Description ↓ in the first “wide” column:
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.headline)
                            Text(item.desc)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        // Give this text‐column a fixed max width, so it doesn’t push the row too wide:
                        .frame(maxWidth: 200, alignment: .leading)

                        // 3) Spacer so that the last column (type‐picker) stays on the right:
                        Spacer()

                        // 4) A drop-down (Picker) for item.type:
                        //    Bound to item.type, using the array vm.allTypes
//                        Picker("", selection: $item.type) {
//                            ForEach($vm.allTypes, id: \.self) { typeOption in
//                                Text(typeOption).tag(typeOption)
//                            }
//                        }
//                        .pickerStyle(MenuPickerStyle()) // this makes it a drop-down menu
//                        .frame(width: 120)             // fix width so row doesn’t expand too far
//                        .labelsHidden()
                    }
                    .padding(.vertical, 4)
                }
            }

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
