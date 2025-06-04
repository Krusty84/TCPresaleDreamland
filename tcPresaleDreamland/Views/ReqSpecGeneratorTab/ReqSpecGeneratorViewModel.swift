//
//  ExampleViewModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import Foundation

class ReqSpecGeneratorViewModel: ObservableObject {
    @Published var title: String = "Hello, SwiftUI!"

    func changeTitle() {
        title = "Title changed!"
        
        SettingsManager.shared.bomTemperature
        SettingsManager.shared.bomMaxTokens
        
        SettingsManager.shared.reqSpecTemperature
        SettingsManager.shared.reqSpecMaxTokens
        
        SettingsManager.shared.itemsTemperature
        SettingsManager.shared.itemsMaxTokens
    }
}
