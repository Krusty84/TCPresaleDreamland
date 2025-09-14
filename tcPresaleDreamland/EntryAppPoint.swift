//
//  EntryPointApp.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025
//

import SwiftUI
import AppKit
import LoggerHelper

@main
struct EntryPointApp: App {
    init() {
        Helpers.checkInternetConnection {
            LoggerHelper.info("Connected to WAN")
        }
    }
    var body: some Scene {
        WindowGroup {
            MainWindow()
        }
        .commands{
            CommandGroup(replacing: .appInfo) {
                Button("About TCPresaleDreamland") {
                    let credits = NSMutableAttributedString(
                        string: """
                        This tool is your helper for making data in Teamcenter fast. You do not need to invent good names anymore.\nItems, BOM's that normally take a lot of time—are now created in just a few clicks.
                        
                        License: MIT
                        Author: Alexey Sedoykin
                        Contact: www.linkedin.com/in/sedoykin
                        """
                    )

                    // Find range of "www.linkedin.com/in/sedoykin"
                    let contact = "www.linkedin.com/in/sedoykin"
                    if let range = credits.string.range(of: contact) {
                        let nsRange = NSRange(range, in: credits.string)
                        credits.addAttributes([
                            .link: URL(string: "https://www.linkedin.com/in/sedoykin")!,
                            .foregroundColor: NSColor.linkColor,
                            .underlineStyle: NSUnderlineStyle.single.rawValue
                        ], range: nsRange)
                    }

                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .credits: credits
                        ]
                    )
                }
            }
        }
    }
}


 
 

