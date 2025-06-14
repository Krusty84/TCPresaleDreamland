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
    }
}


 
 

