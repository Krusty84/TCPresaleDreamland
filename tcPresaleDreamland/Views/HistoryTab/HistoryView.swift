//
//  HistoryView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 08/06/2025.
//

import SwiftUI

struct HistoryContent: View {
    //@StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("This will be in the next episodes...")
                .font(.title)
        }
        .padding()
    }
}

#if DEBUG
struct HistoryContent_Previews: PreviewProvider {
    static var previews: some View {
        HistoryContent()
    }
}
#endif
