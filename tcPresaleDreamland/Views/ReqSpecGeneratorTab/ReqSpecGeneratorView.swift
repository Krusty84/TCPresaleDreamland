//
//  ExampleView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import SwiftUI

struct ReqSpecGeneratorContent: View {
    @StateObject private var viewModel = ReqSpecGeneratorViewModel()

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
struct ReqSpecGeneratorContent_Previews: PreviewProvider {
    static var previews: some View {
        ReqSpecGeneratorContent()
    }
}
#endif
