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
        VStack(spacing: 16) {
            Text("This will be in the next episodes...")
                .font(.title)
        }
        .padding()
    }
}

#if DEBUG
//struct BomGeneratorContent_Previews: PreviewProvider {
//    static var previews: some View {
//        BomGeneratorContent()
//    }
//}
#endif
