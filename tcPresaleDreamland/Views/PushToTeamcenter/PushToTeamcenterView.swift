//
//  PushToTeamcenterView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 06/06/2025.
//

import SwiftUI

struct PushToTCView: View {
    let uid: String
    let containerFolderName: String
    let buttonAction: @Sendable () async -> Void

    private var awcBase: String { SettingsManager.shared.awcURL }
    private var isAWC: Bool { !awcBase.isEmpty }
    private var labelText: String {
        isAWC ? "Open in AWC:" : "Find This Folder in TC:"
    }
    private var linkText: String {
        isAWC ? "\(awcBase)/\(uid)" : containerFolderName
    }

    var body: some View {
        HStack {
            // only show the label+link block if uid is non‐empty
            if !uid.isEmpty {
                Text(labelText)
                
                if isAWC, let url = URL(string: linkText) {
                    Link(linkText, destination: url)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text(linkText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button("Push to TC") {
                Task { await buttonAction() }
            }.help("Send the generated items to Teamcenter")
        }
        .padding()
    }
}



