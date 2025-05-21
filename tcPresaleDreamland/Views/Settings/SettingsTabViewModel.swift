//
//  SettingsTabViewModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import Foundation
import Combine

class SettingsTabViewModel: ObservableObject {
    @Published var appLoggingEnabled: Bool {
        didSet {
            SettingsManager.shared.appLoggingEnabled = appLoggingEnabled
        }
    }

    @Published var username: String {
        didSet {
            SettingsManager.shared.username = username
        }
    }

    init() {
        let settingsMgr = SettingsManager.shared
        self.appLoggingEnabled = settingsMgr.appLoggingEnabled
        self.username          = settingsMgr.username
    }
}
