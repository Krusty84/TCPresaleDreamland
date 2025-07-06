//
//  GeneratedBOMDataByLLM+CoreDataProperties.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 27/06/2025.
//
//

import Foundation
import CoreData


extension GeneratedBOMDataByLLM {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GeneratedBOMDataByLLM> {
        return NSFetchRequest<GeneratedBOMDataByLLM>(entityName: "GeneratedBOMDataByLLM")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var rawResponse: Data?
    @NSManaged public var timestamp: Date?

}

extension GeneratedBOMDataByLLM : Identifiable {

}
