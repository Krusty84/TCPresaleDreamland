//
//  MainWindow.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025
//

import SwiftUI
/**
 
 ## Don't forget to add the `ElegantTabs` dependency:
 
 1. Click File → Add Packages…
 2. In the search box in the upper right, enter:
 https://github.com/Krusty84/ElegantTabs
 3. Click Add Package
 4. Click Add Package, again
 
 */
import ElegantTabs

struct MainWindow: View {
    @State private var selectedTab = 0
    var body: some View {
        ElegantTabsView(selection: $selectedTab) {
            TabItem(title: "Items Generator", icon: .system(name: "batteryblock.stack")) {
                ItemsGeneratorContent()
            }
            TabItem(title: "BOM Generator", icon: .system(name: "list.bullet.indent")) {
                BomGeneratorContent()
            }
            TabItem(title: "Req Spec Generator", icon: .system(name: "text.document")) {
                ReqSpecGeneratorContent()
            }
            TabItem(title: "Settings", icon: .system(name: "gearshape.fill")) {
                SettingsTabContent()
            }
            TabItem(title: "About", icon: .system(name: "info")) {
                AboutTabContent()
            }
        }
    }
}

#Preview {
    MainWindow()
}
