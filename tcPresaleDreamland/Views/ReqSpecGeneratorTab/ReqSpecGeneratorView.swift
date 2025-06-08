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
            Text("This will be in the next episodes...")
                .font(.title)
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
