//
//  PushToTeamcenterView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 06/06/2025.
//

import SwiftUI

struct PushToTCView: View {
    // UID of the newly created Teamcenter folder (empty until creation).
    let uid: String
    // Human‑readable folder name, used in the fallback text.
    let containerFolderName: String
    // Async callback that stores the batch to Core Data history.
    let pushToHistoryAction: @Sendable () async -> Void
    // Async callback that sends the items to Teamcenter.
    let pushToTCVoidAction: @Sendable () async -> Void
    
    // Build an Active Workspace deep‑link *only* when the user configured
    // an AWC base URL. Otherwise, `awcURL` is nil and we fall back to plain
    // text that tells the user where to find the folder.
    private var awcURL: URL? {
        guard !SettingsManager.shared.awcURL.isEmpty else { return nil }
        return URL(string: APIConfig.awcOpenDataPath(awcUrl: SettingsManager.shared.awcURL) + uid)
    }
    
    // Used to change the cursor to a pointing hand when the user hovers over
    // the "Open in AWC" link.  macOS‑only, no effect on iOS.
    @State private var isHovering = false

    var body: some View {
        HStack {
            // --------------------------- Status area ----------------------
            Text("Status:")
            // Show status only when a UID exists
            if !uid.isEmpty {
                if let url = awcURL {
                    // Deep‑link available → present as clickable link
                    Link("Open in AWC", destination: url)
                        .onHover { hovering in
                            isHovering = hovering
                            hovering ? NSCursor.pointingHand.push() : NSCursor.pop()
                        }
                } else {
                    // No AWC base URL set → instruct user to search in TC
                    Text("Find \"\(containerFolderName)\" folder in TC")
                }
            }
            Spacer()
            
            // --------------------------- Action buttons -------------------
            Button("Save to History") {
                // Run callback on background Task so UI stays responsive.
                Task { await pushToHistoryAction() }
            }
            Button("Push to TC") {
                // Creates the selected items inside Teamcenter.
                Task { await pushToTCVoidAction() }
            }
        }
        .padding() // Equal padding on all sides so buttons are not cramped.
    }
}




