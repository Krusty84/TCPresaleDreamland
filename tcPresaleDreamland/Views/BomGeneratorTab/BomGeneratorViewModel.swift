//
//  ExampleViewModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import Foundation

class BomGeneratorViewModel: ObservableObject {
    private let tcApi = TeamcenterAPIService.shared
    @Published var productName: String = ""
    @Published var bomData: BOMData?
    @Published var isLoading: Bool = false
    
    func generateBOM()  {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.bomData = BOMData(
                product: self.productName,
                components: [
                    Component(
                        name: "Processor",
                        quantity: 1,
                        subComponents: [
                            SubComponent(name: "Silicon Wafer", quantity: 1),
                            SubComponent(name: "Thermal Paste", quantity: 0.01)
                        ]
                    ),
                    Component(
                        name: "Memory",
                        quantity: 2,
                        subComponents: [
                            SubComponent(name: "DRAM Chip", quantity: 8),
                            SubComponent(name: "PCB", quantity: 1)
                        ]
                    )
                ]
            )
            self.isLoading = false
        }
    }
}

struct BOMData: Codable {
    let product: String
    let components: [Component]
}

struct Component: Codable, Identifiable {
    var id = UUID()
    let name: String
    let quantity: Int
    let subComponents: [SubComponent]?
}

struct SubComponent: Codable, Identifiable {
    var id = UUID()
    let name: String
    let quantity: Double
}
