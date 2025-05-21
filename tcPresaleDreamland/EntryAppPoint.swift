//
//  EntryPointApp.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025
//

import SwiftUI
import AppKit

@main

struct EntryPointApp: App {
    init() {
        Helpers.checkInternetConnection {
                print("Connected to WAN")
        }
    }
    var body: some Scene {
        WindowGroup {
            MainWindow()
        }
    }
}


 
 

