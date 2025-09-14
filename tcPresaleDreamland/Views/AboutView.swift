//
//  About.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import SwiftUI
import AppKit

struct AboutTabContent: View {
    var body: some View {
        VStack(spacing: 12) {
            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)
                .cornerRadius(10)

            // Description
            Text("tcPresaleDreamland")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 4) {
                Text("This tool is your helper for making data in Teamcenter fast. You do not need to invent good names anymore.\nItems, BOM's that normally take a lot of time—are now created in just a few clicks.")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)

            Divider()

            // Two Columns
            HStack(alignment: .top, spacing: 32) {
                // License & Author
                VStack(alignment: .leading, spacing: 4) {
                    Group {
                        Text("License: MIT")
                        Text("Author: Alexey Sedoykin")
                        Text("Contact: www.linkedin.com/in/sedoykin")
                            .onHover { hovering in
                                if hovering { NSCursor.pointingHand.push() }
                                else       { NSCursor.pop() }
                            }
                    }
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)

                // Exit Button
                VStack {
                    Spacer()
                    Spacer()
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Text("Exit")
                            //.font(.system(size: 12, weight: .medium))
                            .font(.caption)
                            //.foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            //.background(Color.red)
                            .cornerRadius(6)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                }
            }

            Spacer()
        }
        .padding(.vertical, 16)
        //.frame(width: 300, height: 300)
        .onAppear {
            // Any additional setup when the view appears
        }
    }
}
