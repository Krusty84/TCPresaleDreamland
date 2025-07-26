//
//  PushToTeamcenterView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 06/06/2025.
//

import SwiftUI

struct PushToTCView: View {
    // UID of the created Teamcenter object (folder or item rev).
    let uid: String
    let containerFolderName: String

    // Inputs for status during work
    let isLoading: Bool
    let statusMessage: String

    // Actions
    let pushToHistoryAction: @Sendable () async -> Void
    let pushToTCVoidAction:   @Sendable () async -> Void

    // Build AWC deep‑link if base URL is configured
    private var awcURL: URL? {
        guard !SettingsManager.shared.awcURL.isEmpty else { return nil }
        return URL(string: APIConfig.awcOpenDataPath(awcUrl: SettingsManager.shared.awcURL) + uid)
    }

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            Text("Status:")

            // ---------- SUCCESS ----------
            // If transfer is done and we have a UID, show ONLY the link/fallback.
            if !isLoading, !uid.isEmpty {
                if let url = awcURL {
                    Link("Open in AWC", destination: url)
                        .onHover { hovering in
                            isHovering = hovering
                            #if os(macOS)
                            hovering ? NSCursor.pointingHand.push() : NSCursor.pop()
                            #endif
                        }
                } else {
                    Text("Find \"\(containerFolderName)\" folder in TC")
                }

            // ---------- IN PROGRESS ----------
            } else if isLoading {
                ProgressView().scaleEffect(0.9)
                Text(statusMessage.isEmpty ? "Working…" : statusMessage)
                    .lineLimit(1)
                    .truncationMode(.tail)

            // ---------- IDLE / ERROR / INFO ----------
            } else if !statusMessage.isEmpty {
                // Show whatever message you set in the view‑model
                Text(statusMessage)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Text("Idle")
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






