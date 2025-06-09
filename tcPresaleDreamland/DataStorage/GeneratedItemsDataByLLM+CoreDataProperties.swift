//
//  GeneratedItemsDataByLLM+CoreDataProperties.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 09/06/2025.
//
//

import Foundation
import CoreData


extension GeneratedItemsDataByLLM {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GeneratedItemsDataByLLM> {
        return NSFetchRequest<GeneratedItemsDataByLLM>(entityName: "GeneratedItemsDataByLLM")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var rawResponse: Data?
    @NSManaged public var timestamp: Date?

}

extension GeneratedItemsDataByLLM : Identifiable {

}
