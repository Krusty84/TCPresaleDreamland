//
//  ExampleView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import SwiftUI

struct BomGeneratorContent: View {
    @StateObject private var viewModel = BomGeneratorViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top controls (left-aligned)
            HStack {
                TextField("Product name", text: $viewModel.productName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                Button("Generate BOM") {
                    viewModel.generateBOM()
                }
                .disabled(viewModel.productName.isEmpty)
            }
            .padding()
            
            Divider()
            
            // Content area
            if let bomData = viewModel.bomData {
                JSONTreeView(encodable: bomData)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Enter a product name and click Generate BOM")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

#if DEBUG
struct BomGeneratorContent_Previews: PreviewProvider {
    static var previews: some View {
        BomGeneratorContent()
    }
}
#endif
