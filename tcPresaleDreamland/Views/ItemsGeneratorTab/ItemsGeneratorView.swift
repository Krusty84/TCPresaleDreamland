//
//  ExampleView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import SwiftUI

struct ItemsGeneratorContent: View {
    @StateObject private var viewModel = ItemsGeneratorViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text(viewModel.title)
                .font(.title)
            Button("Change Title") {
                viewModel.changeTitle()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#if DEBUG
struct ItemsGeneratorContent_Previews: PreviewProvider {
    static var previews: some View {
        ItemsGeneratorContent()
    }
}
#endif
