//
//  PersistenceController.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 27/06/2025.
//


import CoreData

struct StorageController {
    static let shared = StorageController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // 1. Load the merged model from your single .xcdatamodeld
        let modelName = "HistoryData"   // name of your .xcdatamodeld file
        guard let modelURL = Bundle.main.url(
                forResource: modelName, withExtension: "momd"
        ), let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            fatalError("Failed to locate Core Data model")
        }

        // 2. Create the container with that model
        container = NSPersistentContainer(
            name: modelName,
            managedObjectModel: model
        )

        if inMemory {
            container.persistentStoreDescriptions.first?.url =
                URL(fileURLWithPath: "/dev/null")
        }

        // 3. Load the store
        container.loadPersistentStores { desc, error in
            if let error = error {
                fatalError("Core Data store failed: \(error)")
            }
        }

        // 4. Merge policy & auto‐merge
        container.viewContext.mergePolicy =
            NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}


/*
 struct PersistenceControllerGeneratedBOMData {
     static let shared = PersistenceControllerGeneratedBOMData()

     let container: NSPersistentContainer

     init(inMemory: Bool = false) {
         container = NSPersistentContainer(name: "GeneratedBOMDataByLLM")
         if inMemory {
             container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
         }
         container.loadPersistentStores { desc, error in
             if let error = error {
                 fatalError("Core Data store failed: \(error)")
             }
         }
         container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
         container.viewContext.automaticallyMergesChangesFromParent = true
     }
 }

 */
