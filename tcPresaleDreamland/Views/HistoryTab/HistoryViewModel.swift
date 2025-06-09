//
//  HistoryViewModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 09/06/2025.
//

import Foundation
import SwiftUI
import Combine

class HistoryViewModel: ObservableObject {
    // section toggles
    @Published var isItemsHistorySectionExpanded = false
    @Published var isBOMsHistorySectionExpanded = false
    @Published var isReqSpecHistorySectionExpanded = false

    // data
    @Published var itemsHistory: [GeneratedItemsDataByLLM] = []
    // you can add:
    // @Published var bomsHistory: [StoredBOM] = []
    // @Published var reqSpecsHistory: [StoredReqSpec] = []

    private let viewContext: NSManagedObjectContext

    init(
        context: NSManagedObjectContext = PersistenceControllerGeneratedItemsData.shared.container.viewContext
    ) {
        self.viewContext = context
        loadItemsHistory()
        // loadBOMsHistory()
        // loadReqSpecHistory()
    }

    func loadItemsHistory() {
        let request: NSFetchRequest<GeneratedItemsDataByLLM> = GeneratedItemsDataByLLM.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \GeneratedItemsDataByLLM.timestamp, ascending: false)
        ]
        do {
            itemsHistory = try viewContext.fetch(request)
        } catch {
            print("❌ Fetch StoredItem error:", error)
        }
    }

    // stub methods for when you add those entities:
    // func loadBOMsHistory() { … }
    // func loadReqSpecHistory() { … }
}
