//
//  MainWindow.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025
//

import SwiftUI
import ElegantTabs

struct MainWindow: View {
    @State private var selectedTab = 0
    @StateObject private var itemsGeneratorVM = ItemsGeneratorViewModel()
    var body: some View {
        ElegantTabsView(selection: $selectedTab) {
            TabItem(title: "Items Generator", icon: .system(name: "batteryblock.stack")) {
                ItemsGeneratorContent(vm: itemsGeneratorVM)
            }
            TabItem(title: "BOM Generator", icon: .system(name: "list.bullet.indent")) {
                BomGeneratorContent()
            }
            TabItem(title: "Req Spec Generator", icon: .system(name: "text.document")) {
                ReqSpecGeneratorContent()
            }
            TabItem(title: "History", icon: .system(name: "clock"))
            {
                HistoryContent(vmItemsGeneratorViewModel: itemsGeneratorVM)
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

//#Preview {
//    MainWindow()
//}
