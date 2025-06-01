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
    private let deepSeekApi = DeepSeekAPIService.shared
    private let tcApi = TeamcenterAPIService.shared
    @Published var apiKeyValid: Bool = false
    @Published var isLoading: Bool = false
    @Published var responseCode: Int?            // for DeepSeek verify
    @Published var errorMessage: String?
    
    // New properties for Teamcenter login result:
    @Published var tcSessionId: String?          // holds JSESSIONID on success
    @Published var tcResponseCode: Int?
    @Published var tcErrorMessage: String?
    
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
                let isValid = try await deepSeekApi.verifyAPIKey(apiKey: apiKey)
                
                DispatchQueue.main.async {
                    self.apiKeyValid = isValid
                    self.responseCode = isValid ? 200 : 400
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
                            LoggerHelper.error("Invalid DeepSeek API Key")
                        case .httpError(let code):
                            self.responseCode = code
                            self.errorMessage = "verifyAPIKey Key Error (\(code))"
                            LoggerHelper.error("verifyAPIKey Key Error: \(code)")
                        default:
                            self.errorMessage = error.localizedDescription
                            LoggerHelper.error("verifyAPIKey Error: \(error.localizedDescription)")
                        }
                    } else {
                        self.errorMessage = error.localizedDescription
                        LoggerHelper.error("verifyAPIKey Error: \(error.localizedDescription)")
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
    
    /// Calls TeamcenterAPIService.login(...) with the saved tcUsername / tcPassword.
    /// Updates `tcSessionId` (on success) or `tcErrorMessage` (on failure).
    func verifyTCConnect() {
        // Reset any previous TC-related state:
        tcSessionId = nil
        tcResponseCode = nil
        tcErrorMessage = nil
        isLoading = true
        
        Task {
            // Make sure SettingsManager.shared.tcURL is up to date
            // (TeamcenterAPIService.login reads Settings.tcURL internally).
            // You might want to re-assign it here if you let users edit it in the UI.
            
            do {
                // Call existing login(...) method:
                let sessionId = await tcApi.tcLogin(tcEndpointUrl: APIConfig.tcLoginUrl(tcUrl: tcURL),userName: tcUsername,userPassword: tcPassword
                )
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let validSession = sessionId {
                        // login succeeded
                        self.tcSessionId = validSession
                        self.tcResponseCode = 200
                        LoggerHelper.info("TC login succeeded. JSESSIONID: \(validSession)")
                    } else {
                        // login returned nil → treat as failure
                        self.tcResponseCode = 401
                        self.tcErrorMessage = "Teamcenter login failed"
                        LoggerHelper.error("Teamcenter login failed. No JSESSIONID returned.")
                    }
                }
            } catch {
                // In case login(...) ever throws (it currently returns nil on failure, but handle defensively)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.tcSessionId = nil
                    self.tcResponseCode = nil
                    self.tcErrorMessage = error.localizedDescription
                    LoggerHelper.error("Error during TC login: \(error.localizedDescription)")
                }
            }
        }
    }
}


