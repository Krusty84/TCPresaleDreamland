//
//  PushToTeamcenterView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 06/06/2025.
//

import SwiftUI

struct PushToTCView: View {
    @Binding var link: String
    var pushAction: () -> Void

    init(
        link: Binding<String> = .constant("https://example.com"),
        pushAction: @escaping () -> Void = {}
    ) {
        self._link = link
        self.pushAction = pushAction
    }

    var body: some View {
        HStack {
            // Label and clickable link instead of text field
            Text("Open in AWC:")
            
            if let url = URL(string: link), !link.isEmpty {
                Link(link, destination: url)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text("No link available")
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Push to TC") {
                pushAction()
            }
            .disabled(link.isEmpty)
        }
        .padding()
    }
}
