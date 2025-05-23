//
//  SettingsTabViewModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import Foundation
import Combine
import LoggerHelper

class SettingsTabViewModel: ObservableObject {
    private let deepSeekAPI = DeepSeekAPIService.shared
    @Published var apiKeyValid: Bool = false
    @Published var isLoading: Bool = false
    @Published var responseCode: Int?  // Added to track HTTP status code
    @Published var errorMessage: String?
    //
    @Published var appLoggingEnabled: Bool {
        didSet { SettingsManager.shared.appLoggingEnabled = appLoggingEnabled }
    }

    @Published var apiKey: String {
        didSet { SettingsManager.shared.apiKey = apiKey }
    }
    
    @Published var bomPrompt: String {
        didSet { SettingsManager.shared.bomPrompt = bomPrompt }
    }
    @Published var reqSpecPrompt: String {
        didSet { SettingsManager.shared.reqSpecPrompt = reqSpecPrompt }
    }
    @Published var itemsPrompt: String {
        didSet { SettingsManager.shared.itemsPrompt = itemsPrompt }
    }

    @Published var tcURL: String {
        didSet { SettingsManager.shared.tcURL = tcURL }
    }
    @Published var awcURL: String {
        didSet { SettingsManager.shared.awcURL = awcURL }
    }
    @Published var tcUsername: String {
        didSet { SettingsManager.shared.tcUsername = tcUsername }
    }
    @Published var tcPassword: String {
        didSet { SettingsManager.shared.tcPassword = tcPassword }
    }

    init() {
        let mgr = SettingsManager.shared
        self.appLoggingEnabled = mgr.appLoggingEnabled
        self.apiKey = mgr.apiKey
        self.bomPrompt = mgr.bomPrompt
        self.reqSpecPrompt = mgr.reqSpecPrompt
        self.itemsPrompt = mgr.itemsPrompt
        self.tcURL = mgr.tcURL
        self.awcURL = mgr.awcURL
        self.tcUsername = mgr.tcUsername
        self.tcPassword = mgr.tcPassword
    }

    func verifyAPIKey() {
            isLoading = true
            errorMessage = nil
            responseCode = nil
            
            Task {
                do {
                    let isValid = try await deepSeekAPI.verifyAPIKey(apiKey: apiKey)
                    
                    DispatchQueue.main.async {
                        self.apiKeyValid = isValid
                        self.responseCode = isValid ? 200 : 400  // 200 = valid, 400 = payload error but key valid
                        self.isLoading = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.apiKeyValid = false
                        
                        if let apiError = error as? APIError {
                            switch apiError {
                            case .unauthorized:
                                self.responseCode = 401
                                self.errorMessage = "Invalid DeepSeek API Key"
                                LoggerHelper.error ("Invalid DeepSeek API Key")
                            case .httpError(let code):
                                self.responseCode = code
                                self.errorMessage = "verifyAPIKey Key Error (\(code))"
                                LoggerHelper.error ("verifyAPIKey Key Error: \(code)")
                            default:
                                self.errorMessage = error.localizedDescription
                                LoggerHelper.error ("verifyAPIKey Error: \(error.localizedDescription)")
                            }
                        } else {
                            self.errorMessage = error.localizedDescription
                            LoggerHelper.error ("verifyAPIKey Error: \(error.localizedDescription)")
                        }
                        
                        self.isLoading = false
                    }
                }
            }
        }


    func resetPromptsToDefault() {
        bomPrompt = SettingsManager.shared.defaultBOMPrompt
        reqSpecPrompt = SettingsManager.shared.defaultReqSpecPrompt
        itemsPrompt = SettingsManager.shared.defaultItemsPrompt
    }

    func verifyTCConnect() {
        // Any additional save logic if needed
    }
}

