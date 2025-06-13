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
    let pushToHistoryAction: @Sendable () async -> Void
    let pushToTCVoidAction: @Sendable () async -> Void
    
    // build a URL only when awcBase isn’t empty
    private var awcURL: URL? {
        guard !SettingsManager.shared.awcURL.isEmpty else { return nil }
        return URL(string: APIConfig.awcOpenDataPath(awcUrl: SettingsManager.shared.awcURL)+uid)
    }
    @State private var isHovering = false

    var body: some View {
        HStack {
            Text("Status:")
            if !uid.isEmpty {
                if let url = awcURL {
                    // only “Open AWC” is shown
                    Link("Open in AWC", destination: url)
                        .onHover { hovering in
                            isHovering = hovering
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                } else {
                    // fallback for TC
                    Text("Find \"\(containerFolderName)\" folder in TC")
                }
            }
            
            Spacer()
        
            Button("Save to History") {
                Task { await pushToHistoryAction() }
            }
            Button("Push to TC") {
                Task { await pushToTCVoidAction() }
            }
        }
        .padding()
    }
}




