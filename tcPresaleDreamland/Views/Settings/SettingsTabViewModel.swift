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
    private let tcHelpers = TCHelpers.shared
    @Published var apiKeyValid: Bool = false
    @Published var isLoading: Bool = false
    @Published var responseCode: Int?            // for DeepSeek verify
    @Published var errorMessage: String?
    
    // New properties for Teamcenter login result:
    @Published var tcSessionId: String?          // holds JSESSIONID on success
    @Published var tcResponseCode: Int?
    @Published var tcErrorMessage: String?
    
    //for UI
    @Published var isBOMSectionExpanded = false
    @Published var isReqSpecSectionExpanded = false
    @Published var isItemsSectionExpanded = false
    @Published var isTeamcenterGeneral = true
    @Published var isTeamcenterObjectType = false
    @Published var isTeamcenterDataTargetFolder = false
    
    @Published var appLoggingEnabled: Bool {
        didSet { SettingsManager.shared.appLoggingEnabled = appLoggingEnabled }
    }
    
    @Published var apiKey: String {
        didSet { SettingsManager.shared.apiKey = apiKey }
    }
    
    @Published var bomPrompt: String {
        didSet { SettingsManager.shared.bomPrompt = bomPrompt }
    }
    
    @Published var bomTemperature: Double {
        didSet { SettingsManager.shared.bomTemperature = bomTemperature }
    }
    
    @Published var bomMaxTokens: Int {
        didSet { SettingsManager.shared.bomMaxTokens = bomMaxTokens }
    }
    
    @Published var reqSpecPrompt: String {
        didSet { SettingsManager.shared.reqSpecPrompt = reqSpecPrompt }
    }
    
    @Published var reqSpecTemperature: Double {
        didSet { SettingsManager.shared.reqSpecTemperature = reqSpecTemperature }
    }
    
    @Published var reqSpecMaxTokens: Int {
        didSet { SettingsManager.shared.reqSpecMaxTokens = reqSpecMaxTokens }
    }
    
    @Published var itemsPrompt: String {
        didSet { SettingsManager.shared.itemsPrompt = itemsPrompt }
    }
    
    @Published var itemsTemperature: Double {
        didSet { SettingsManager.shared.itemsTemperature = itemsTemperature }
    }
    
    @Published var itemsMaxTokens: Int {
        didSet { SettingsManager.shared.itemsMaxTokens = itemsMaxTokens }
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
    
    @Published var tcUserUid: String {
        didSet { SettingsManager.shared.tcUserUid = tcUserUid }
    }
    
    @Published var tcUserHomeFolderUid: String {
        didSet { SettingsManager.shared.tcUserHomeFolderUid = tcUserHomeFolderUid }
    }
    
    @Published var homeFolderContent: [[String: Any]] = []
    
    init() {
        let mgr = SettingsManager.shared
        self.appLoggingEnabled = mgr.appLoggingEnabled
        self.apiKey = mgr.apiKey
        self.bomPrompt = mgr.bomPrompt
        self.bomTemperature = mgr.bomTemperature
        self.bomMaxTokens = mgr.bomMaxTokens
        self.reqSpecPrompt = mgr.reqSpecPrompt
        self.reqSpecTemperature = mgr.reqSpecTemperature
        self.reqSpecMaxTokens = mgr.reqSpecMaxTokens
        self.itemsPrompt = mgr.itemsPrompt
        self.itemsTemperature = mgr.itemsTemperature
        self.itemsMaxTokens = mgr.itemsMaxTokens
        self.tcURL = mgr.tcURL
        self.awcURL = mgr.awcURL
        self.tcUsername = mgr.tcUsername
        self.tcPassword = mgr.tcPassword
        self.tcUserUid = mgr.tcUserUid
        self.tcUserHomeFolderUid = mgr.tcUserHomeFolderUid
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
    
    func resetBOMToDefault() {
        bomPrompt = SettingsManager.shared.defaultBOMPrompt
        bomTemperature = SettingsManager.shared.defaultBomTemperature
        bomMaxTokens = SettingsManager.shared.defaultBomMaxTokens
    }
    
    func resetReqSpecToDefault() {
        reqSpecPrompt = SettingsManager.shared.defaultReqSpecPrompt
        reqSpecTemperature = SettingsManager.shared.defaultReqSpecTemperature
        reqSpecMaxTokens = SettingsManager.shared.defaultReqSpecMaxTokens
    }
    
    func reseItemsToDefault() {        
        itemsPrompt = SettingsManager.shared.defaultItemsPrompt
        itemsTemperature = SettingsManager.shared.defaultItemsTemperature
        itemsMaxTokens = SettingsManager.shared.defaultItemsMaxTokens
    }
    
    /// Calls TeamcenterAPIService.login(...) with the saved tcUsername / tcPassword.
    /// Updates `tcSessionId` (on success) or `tcErrorMessage` (on failure).
    
    func verifyTCConnect() async {
        // 1) Reset state on the main actor
        tcSessionId = nil
        tcResponseCode = nil
        tcErrorMessage = nil
        isLoading = true

        // 2) Attempt login (these calls run off the main actor, but when we assign back, we're on MainActor)
        let sessionId = await tcApi.tcLogin(
            tcEndpointUrl: APIConfig.tcLoginUrl(tcUrl: tcURL),
            userName: tcUsername,
            userPassword: tcPassword
        )

        // 3) If login failed:
        guard let validSession = sessionId else {
            isLoading = false
            tcResponseCode = 401
            tcErrorMessage = "Teamcenter login failed"
            LoggerHelper.error("TC login failed; no JSESSIONID returned.")
            return
        }

        // 4) Login succeeded: publish on main actor
        tcSessionId = validSession

        // 5) Fetch session info
        let rawSessionInfo = await tcApi.getTcSessionInfo(
            tcEndpointUrl: APIConfig.tcSessionInfoUrl(tcUrl: tcURL)
        )

        if let info = rawSessionInfo {
            // still on MainActor
            tcResponseCode = 200
            tcUserUid = info.user.uid
        } else {
            tcResponseCode = 200
            tcErrorMessage = "Could not fetch session info"
            LoggerHelper.error("getSessionInfo returned nil")
        }

        // 6) Fetch the user’s home‐folder UID
        let rawHomeFolderUid = await tcApi.getUserHomeFolder(
            tcEndpointUrl: APIConfig.tcGetPropertiesUrl(tcUrl: tcURL),
            userUid: tcUserUid
        )

        if let folderUid = rawHomeFolderUid {
            tcUserHomeFolderUid = folderUid
        } else {
            tcErrorMessage = "Could not fetch homefolder UID"
            LoggerHelper.error("getUserHomeFolder returned nil")
        }

        // 7) Expand the folder contents
        if let folderArray = await tcApi.expandFolder(
            tcUrl: tcURL,
            folderUid: tcUserHomeFolderUid,
            expItemRev: false,
            latestNRevs: -1,
            info: [],
            contentTypesFilter: [],
            propertyAttributes: ["object_name", "object_desc", "creation_date"]
        ) {
            // Still on MainActor, so it’s safe to assign to your @Published array
            homeFolderContent = folderArray
        } else {
            print("expandFolder returned nil or failed")
        }

        // 8) Finally, stop the loading indicator
        isLoading = false
    }

}


