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
            ZStack {
                List(vm.generatedItems, id: \.name) { item in
                    VStack(alignment: .leading) {
                        Text(item.name).font(.headline)
                        Text(item.desc).foregroundColor(.secondary)
                    }
                }
                
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                if let errorMessage = vm.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
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
