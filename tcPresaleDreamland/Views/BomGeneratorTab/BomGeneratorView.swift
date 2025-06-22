//
//  ExampleView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import SwiftUI

struct BomGeneratorContent: View {
    @StateObject private var vm = BomGeneratorViewModel()
    var generatedBOMJSON: String {
        guard
            let data = try? JSONEncoder().encode(vm.generatedBOM),
            let json = String(data: data, encoding: .utf8)
        else { return "Encoding failed" }
        return json
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0){
            CallLLMView(
                domainName:   $vm.domainName,
                countText:    $vm.count,
                temperature:  $vm.bomTemperature,
                maxTokens:    $vm.bomMaxTokens,
                isLoading:    vm.isLoading,
                generateAction: vm.generateBOM,
                generateButtonLabel: "Generate BOM",
                generateButtonHelp: "Ask DeepSeek to generate a list of items"
            ) .padding()
            
            Divider()
            
            
            //                    List {
            //                        OutlineGroup(
            //                            vm.generatedBOM,
            //                            children: \.children
            //                        ) { item in
            //                            HStack {
            //                                Text(item.name)
            //                                    .font(.headline)
            //                                Spacer()
            //                                Text(item.desc)
            //                                    .font(.subheadline)
            //                                    .foregroundColor(.secondary)
            //                            }
            //                            .padding(.vertical, 2)
            //                        }
            //                    }
            //                    .listStyle(SidebarListStyle())
            
            NavigationView {
                Table(vm.generatedBOM, children: \.children) {
                     // Checkbox column
                     TableColumn("Select") { item in
                         Toggle("", isOn: Binding(
                             get: { item.isEnabled },
                             set: { newValue in vm.setEnabled(id: item.id, to: newValue) }
                         ))
                         .toggleStyle(.checkbox)
                         .labelsHidden()
                     }
                     // Name column
                     TableColumn("Name", value: \.name)
                     // Description column
                     TableColumn("Desc", value: \.desc)
                     // Type column
                     TableColumn("Type", value: \.type)
                 }
            }
            
            PushToTCView(
                uid: vm.containerFolderUid,
                containerFolderName: vm.domainName,
                pushToHistoryAction: {
                    await vm.saveGeneratedBOMToHistory()
                },
                pushToTCVoidAction: {
                    let report = await vm.createBOM()
                    let failures = report.filter { !$0.success }.map(\.productName)
                    if !failures.isEmpty {
                        // TODO: Show alert with failures.
                    }
                }
            )
            .disabled(vm.generatedBOM.allSatisfy { !$0.isEnabled })
            
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

#if DEBUG
//struct BomGeneratorContent_Previews: PreviewProvider {
//    static var previews: some View {
//        BomGeneratorContent()
//    }
//}
#endif
