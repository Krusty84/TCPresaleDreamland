//
//  ExampleView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import SwiftUI

struct ItemsGeneratorContent: View {
    @StateObject private var vm = ItemsGeneratorViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top controls (left-aligned)
            HStack {
                TextField("Domain", text: $vm.domainName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                TextField("Number", text: $vm.count)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                Button("Generate Items") {
                    vm.generateItems()
                }
                .disabled(vm.isLoading)
            }
            .padding()
            
            Divider()
            
            if vm.isLoading {
                       ProgressView()
                   }
                   
                   if let errorMessage = vm.errorMessage {
                       Text(errorMessage)
                           .foregroundColor(.red)
                   }
                   
                   List(vm.generatedItems, id: \.name) { item in
                       VStack(alignment: .leading) {
                           Text(item.name).font(.headline)
                           Text(item.desc).foregroundColor(.secondary)
                       }
                   }
            
            // Content area
          
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

#if DEBUG
struct ItemsGeneratorContent_Previews: PreviewProvider {
    static var previews: some View {
        ItemsGeneratorContent()
    }
}
#endif
