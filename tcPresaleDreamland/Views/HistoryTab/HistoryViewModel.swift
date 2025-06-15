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

    // Restore the selected histoy item to Items Generator View
    func restoreItemHistory(
        selectedRowId: Set<GeneratedItemsDataByLLM.ID>,
        itemsGeneratorViewModel itemVM: ItemsGeneratorViewModel
    ) {
        var allItems: [Item] = []
        for item in itemsHistory
                
          where selectedRowId.contains(item.id!)
        {
            itemVM.domainName = item.name!
            if let data = item.rawResponse,
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
    
    // Delete the selected history item
    func deleteItemHistoty(selectedRowId: Set<GeneratedItemsDataByLLM.ID>) {
        for item in itemsHistory
          where selectedRowId.contains(item.id!)
        {
            context.delete(item)
        }
        do {
            try context.save()
        } catch {
            print("❌ Delete error:", error)
        }
        // reload to refresh the list
        loadItemsHistory()
    }
    
    
    func exportItemsDataToJSONFile(
           selectedRowId: Set<GeneratedItemsDataByLLM.ID>
       ) -> Data? {
           // Helper struct to wrap the output
           struct ExportPackage: Codable {
               let containerFolderName: String
               let items: [Item]
           }

           // Find the first batch matching one of the selected IDs
           guard let item = itemsHistory.first(where: {
               if let id = $0.id { return selectedRowId.contains(id) }
               return false
           }) else {
               print("❌ No matching batch to export")
               return nil
           }

           // Decode the rawResponse back into [Item]
           guard
               let raw = item.rawResponse,
               let items = try? JSONDecoder().decode([Item].self, from: raw)
           else {
               print("❌ Failed to decode batch.rawResponse")
               return nil
           }

           // Build the export package
           let package = ExportPackage(
               containerFolderName: item.name ?? "Export",
               items: items
           )

           // Encode to pretty‐printed JSON
           do {
               let encoder = JSONEncoder()
               encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
               return try encoder.encode(package)
           } catch {
               print("❌ Failed to encode export JSON:", error)
               return nil
           }
       }
    
    func importItemsDataFromJSONFile(_ pkg: ImportPackage) {
           context.perform {
               let record = GeneratedItemsDataByLLM(context: self.context)
               record.id = UUID()
               record.name = pkg.containerFolderName
               record.timestamp = Date()
               // Re-encode the items array back into rawResponse
               if let data = try? JSONEncoder().encode(pkg.items) {
                   record.rawResponse = data
               }
               do {
                   try self.context.save()
                   // reload so your view sees the new record
                   DispatchQueue.main.async {
                       self.loadItemsHistory()
                   }
               } catch {
                   print("❌ Failed to import JSON:", error)
               }
           }
       }

       /// The same wrapper you use elsewhere for decoding/encoding
       struct ImportPackage: Codable {
           let containerFolderName: String
           let items: [Item]
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
