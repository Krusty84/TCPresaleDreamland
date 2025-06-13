//
//  HistoryViewModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 09/06/2025.
//

import Foundation
import SwiftUI
import Combine

import Foundation
import CoreData

class HistoryViewModel: ObservableObject {
    // the fetched batches
    @Published var itemsHistory: [GeneratedItemsDataByLLM] = []
    
    private let context: NSManagedObjectContext

    init(
        context: NSManagedObjectContext = PersistenceControllerGeneratedItemsData
            .shared.container.viewContext
    ) {
        self.context = context
        loadItemsHistory()
    }

    /// Load all history, newest first
    func loadItemsHistory() {
        let req: NSFetchRequest<GeneratedItemsDataByLLM> =
            GeneratedItemsDataByLLM.fetchRequest()
        req.sortDescriptors = [
            NSSortDescriptor(
              keyPath: \GeneratedItemsDataByLLM.timestamp,
              ascending: false
            )
        ]
        do {
            itemsHistory = try context.fetch(req)
        } catch {
            print("❌ Fetch error:", error)
            itemsHistory = []
        }
    }

    /// Restore the selected batches into your Item generator VM
    func restore(
        selectedRowId: Set<GeneratedItemsDataByLLM.ID>,
        itemsGeneratorViewModel itemVM: ItemsGeneratorViewModel
    ) {
        var allItems: [Item] = []
        for batch in itemsHistory
                
          where selectedRowId.contains(batch.id!)
        {
            itemVM.domainName = batch.name!
            if let data = batch.rawResponse,
               let items = try? JSONDecoder()
                 .decode([Item].self, from: data)
            {
                allItems.append(contentsOf: items)
            }
        }
        print(allItems)
        // Replace the generated items
        itemVM.generatedItems = allItems
    }

    /// Delete the selected history batches
    func delete(selectedRowId: Set<GeneratedItemsDataByLLM.ID>) {
        for batch in itemsHistory
          where selectedRowId.contains(batch.id!)
        {
            context.delete(batch)
        }
        do {
            try context.save()
        } catch {
            print("❌ Delete error:", error)
        }
        // reload to refresh the list
        loadItemsHistory()
    }

     var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }

    // stub methods for when you add those entities:
    // func loadBOMsHistory() { … }
    // func loadReqSpecHistory() { … }
}
