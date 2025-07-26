//
//  HistoryViewModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 09/06/2025.
//

import Foundation
import SwiftUI
import Combine
import CoreData

class HistoryViewModel: ObservableObject {
    // MARK: - Published Data
    @Published var itemsHistory: [GeneratedItemsDataByLLM] = []
    @Published var bomsHistory: [GeneratedBOMDataByLLM] = []
    
    // Shared Core Data context for both entities
    private let context: NSManagedObjectContext
    
    // MARK: - Init
    init(
        context: NSManagedObjectContext = StorageController.shared.container.viewContext
    ) {
        self.context = context
        loadItemsHistory()
        loadBOMsHistory()
    }
    
    // MARK: - Load History
    func loadItemsHistory() {
        let req: NSFetchRequest<GeneratedItemsDataByLLM> = GeneratedItemsDataByLLM.fetchRequest()
        req.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \GeneratedItemsDataByLLM.timestamp,
                ascending: false
            )
        ]
        do {
            itemsHistory = try context.fetch(req)
        } catch {
            print("❌ Fetch itemsHistory error:", error)
            itemsHistory = []
        }
    }
    
    func loadBOMsHistory() {
        let req: NSFetchRequest<GeneratedBOMDataByLLM> = GeneratedBOMDataByLLM.fetchRequest()
        req.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \GeneratedBOMDataByLLM.timestamp,
                ascending: false
            )
        ]
        do {
            bomsHistory = try context.fetch(req)
        } catch {
            print("❌ Fetch bomsHistory error:", error)
            bomsHistory = []
        }
    }
    
    // MARK: - Restore
    // Restore the selected histoy item to Items Generator View
    @MainActor
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
    
    @MainActor
    func restoreBOMHistory(
        selectedRowIds: Set<GeneratedBOMDataByLLM.ID>,
        bomGeneratorViewModel bomVM: BomGeneratorViewModel
    ) {
        var allBOMs: [BOMItem] = []
        for bom in bomsHistory {
            // unwrap the optional id and only proceed if it’s in the selected set
            guard let id = bom.id,
                  selectedRowIds.contains(id)
            else { continue }
            
            // carry over the batch name
            bomVM.domainName = bom.name ?? ""
            
            // decode the batch’s rawResponse into your BOMItem array
            if let data = bom.rawResponse,
               let decoded = try? JSONDecoder().decode([BOMItem].self, from: data) {
                allBOMs.append(contentsOf: decoded)
            }
        }
        bomVM.generatedBOM = allBOMs
    }
    
    // Delete the selected history item
    func deleteItemHistory(selectedRowId: Set<GeneratedItemsDataByLLM.ID>) {
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
    
    func deleteBOMHistory(selectedRowId: Set<GeneratedBOMDataByLLM.ID>) {
        for bom in bomsHistory
        where selectedRowId.contains(bom.id!)
        {
            context.delete(bom)
        }
        do {
            try context.save()
        } catch {
            print("❌ Delete error:", error)
        }
        // reload to refresh the list
        loadBOMsHistory()
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

    func exportBOMDataToJSONFile(
        selectedRowId: Set<GeneratedBOMDataByLLM.ID>
    ) -> Data? {
        // Helper struct to wrap the output
        struct ExportPackage: Codable {
            let containerFolderName: String
            let bom: [BOMItem]
        }
        
        // Find the first batch matching one of the selected IDs
        guard let bom = bomsHistory.first(where: {
            if let id = $0.id { return selectedRowId.contains(id) }
            return false
        }) else {
            print("❌ No matching batch to export")
            return nil
        }
        
        // Decode the rawResponse back into [Item]
        guard
            let raw = bom.rawResponse,
            let bom_ = try? JSONDecoder().decode([BOMItem].self, from: raw)
        else {
            print("❌ Failed to decode batch.rawResponse")
            return nil
        }
        
        // Build the export package
        let package = ExportPackage(
            containerFolderName: bom.name ?? "Export",
            bom: bom_
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
    
    func importItemsDataFromJSONFile(_ pkg: ImportItemsPackage) {
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
    
    func importBOMDataFromJSONFile(_ pkg: ImportBOMPackage) {
        context.perform {
            let record = GeneratedBOMDataByLLM(context: self.context)
            record.id = UUID()
            record.name = pkg.containerFolderName
            record.timestamp = Date()
            // Re-encode the items array back into rawResponse
            if let data = try? JSONEncoder().encode(pkg.bom) {
                record.rawResponse = data
            }
            do {
                try self.context.save()
                // reload so your view sees the new record
                DispatchQueue.main.async {
                    self.loadBOMsHistory()
                }
            } catch {
                print("❌ Failed to import JSON:", error)
            }
        }
    }
    
    /// The same wrapper you use elsewhere for decoding/encoding
    struct ImportItemsPackage: Codable {
        let containerFolderName: String
        let items: [Item]
    }
    
    struct ImportBOMPackage: Codable {
        let containerFolderName: String
        let bom: [BOMItem]
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

