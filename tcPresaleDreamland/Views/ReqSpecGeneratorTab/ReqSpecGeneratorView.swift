//
//  ExampleView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import SwiftUI

struct ReqSpecGeneratorContent: View {
    @ObservedObject var vm: ReqSpecGeneratorViewModel
    var generatedReqSpecJSON: String {
        guard
            let data = try? JSONEncoder().encode(vm.generatedReqSpec),
            let json = String(data: data, encoding: .utf8)
        else { return "Encoding failed" }
        return json
    }
    
    // Helper that returns a *Binding* to a property of an `Item` in the list.
    private func binding<T>(
        for item: ReqSpecItem,
        keyPath: WritableKeyPath<ReqSpecItem, T>
    ) -> Binding<T> {
        Binding(
            get: { item[keyPath: keyPath] },
            set: { newValue in
                // Search recursively through the BOM tree
                func searchAndUpdate(items: inout [ReqSpecItem], id: UUID) -> Bool {
                    for index in items.indices {
                        if items[index].id == id {
                            items[index][keyPath: keyPath] = newValue
                            return true
                        }
                        if searchAndUpdate(items: &items[index].items, id: id) {
                            return true
                        }
                    }
                    return false
                }
                
                // Start the search from the top level
                _ = searchAndUpdate(items: &vm.generatedReqSpec, id: item.id)
            }
        )
    }
 
    var body: some View {
        VStack(alignment: .leading, spacing: 0){
            CallLLMView(
                domainName:   $vm.domainName,
                countText:    $vm.count,
                temperature:  $vm.reqSpecTemperature,
                maxTokens:    $vm.reqSpecMaxTokens,
                isLoading:    vm.isLoading,
                generateAction: vm.generateReqSpec,
                generateButtonLabel: "Generate Requirements",
                generateButtonHelp: "Ask DeepSeek to generate a requirements specification"
            ) .padding()
            
            Divider()
            
            ZStack {
                Table(vm.generatedReqSpec, children: \.children) {
                     // Checkbox column
                     TableColumn("") { item in
                         Toggle("", isOn: Binding(
                             get: { item.isEnabled },
                             set: { newValue in vm.setEnabled(id: item.id, to: newValue) }
                         ))
                         .toggleStyle(.checkbox)
                         .labelsHidden()
                     }.width(120)
                     // Name column
                     TableColumn("Name", value: \.name)
                        .width(min: 100, max: 200)
                     // Description column
                     TableColumn("Desc", value: \.desc)
                        .width(min: 100, max: 300)
                     // Type column
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
                                vm.updateAllItemTypes(to: item.type)
                            }
                        }
                    }
                 }
                
                if vm.isLoading {
                    Color.black.opacity(0.25) // Dim background
                        .edgesIgnoringSafeArea(.all)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                }
            }
            
            PushToTCView(
                uid: vm.rootReqSpecItemUid,
                containerFolderName: vm.domainName,
                isLoading: vm.isLoading,
                statusMessage: vm.statusMessage,
                pushToHistoryAction: {
                    await vm.saveGeneratedReqSpecToHistory()
                },
                pushToTCVoidAction: {
                    let report = await vm.createReqSpec()
                    let failures = report.filter { !$0.success }.map(\.itemName)
                    if !failures.isEmpty {
                        // TODO: Show alert with failures.
                    }
                }
            )
            .disabled(vm.generatedReqSpec.allSatisfy { !$0.isEnabled })

            
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

#if DEBUG
//struct ReqSpecGeneratorContent_Previews: PreviewProvider {
//    static var previews: some View {
//        ReqSpecGeneratorContent()
//    }
//}
#endif
