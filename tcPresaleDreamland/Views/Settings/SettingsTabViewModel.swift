//
//  SettingsTabViewModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import Foundation
import Combine
import LoggerHelper

@MainActor
class SettingsTabViewModel: ObservableObject {
    private let deepSeekApi = DeepSeekAPIService.shared
    private let tcApi = TeamcenterAPIService.shared
    private let tcHelpers = TCHelpers.shared

    @Published var deepSeekApiKeyValid: Bool = false
    @Published var tcLoginValid: Bool = false
    @Published var isLoading: Bool = false
    @Published var responseCode: Int?            // for DeepSeek verify
    @Published var errorMessage: String?

    // New properties for Teamcenter login result:
    @Published var tcSessionId: String?          // holds JSESSIONID on success
    @Published var tcResponseCode: Int?
    @Published var tcErrorMessage: String?

    // for UI
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

    var isValidTCURL: Bool {
        let pattern = #"^https?://(?:(?:\d{1,3}\.){3}\d{1,3}|(?:[A-Za-z0-9]+\.)*[A-Za-z0-9]+):\d{1,5}/[A-Za-z0-9]+$"#
        return tcURL.range(of: pattern, options: .regularExpression) != nil
    }

    var isValidAWCURL: Bool {
        let awcPattern = #"^https?://(?:(?:\d{1,3}\.){3}\d{1,3}|(?:[A-Za-z0-9]+\.)*[A-Za-z0-9]+):\d{1,5}$"#
        return awcURL.range(of: awcPattern, options: .regularExpression) != nil
    }
    
    let allowedUrlCharacters = CharacterSet(charactersIn:
           "abcdefghijklmnopqrstuvwxyz" +
           "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
           "0123456789" +
           "-._~:/?#[]@!$&'()*+,;=%"
       )

    func verifyDeepSeekAPIKey() {
        isLoading = true
        errorMessage = nil
        responseCode = nil

        Task {
            do {
                let isValid = try await deepSeekApi.verifyAPIKey(apiKey: apiKey)
                deepSeekApiKeyValid = isValid
                responseCode = isValid ? 200 : 400
                isLoading = false
            } catch {
                deepSeekApiKeyValid = false
                if let apiError = error as? APIError {
                    switch apiError {
                    case .unauthorized:
                        responseCode = 401
                        errorMessage = "Invalid DeepSeek API Key"
                        LoggerHelper.error("Invalid DeepSeek API Key")
                    case .httpError(let code):
                        responseCode = code
                        errorMessage = "verifyAPIKey Error (\(code))"
                        LoggerHelper.error("verifyAPIKey Error: \(code)")
                    default:
                        errorMessage = error.localizedDescription
                        LoggerHelper.error("verifyAPIKey Error: \(error.localizedDescription)")
                    }
                } else {
                    errorMessage = error.localizedDescription
                    LoggerHelper.error("verifyAPIKey Error: \(error.localizedDescription)")
                }
                isLoading = false
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
        tcSessionId = nil
        tcResponseCode = nil
        tcErrorMessage = nil
        isLoading = true

        let sessionId = await tcApi.tcLogin(
            tcEndpointUrl: APIConfig.tcLoginUrl(tcUrl: tcURL),
            userName: tcUsername,
            userPassword: tcPassword
        )

        guard let validSession = sessionId else {
            isLoading = false
            tcResponseCode = 401
            tcErrorMessage = "Teamcenter login failed"
            LoggerHelper.error("TC login failed; no JSESSIONID returned.")
            return
        }

        tcSessionId = validSession

        if let info = await tcApi.getTcSessionInfo(
            tcEndpointUrl: APIConfig.tcSessionInfoUrl(tcUrl: tcURL)
        ) {
            tcResponseCode = 200
            tcUserUid = info.user.uid
            tcLoginValid = true
        } else {
            tcResponseCode = 200
            tcErrorMessage = "Could not fetch session info"
            tcLoginValid = false
            LoggerHelper.error("getSessionInfo returned nil")
        }

        if let folderUid = await tcApi.getUserHomeFolder(
            tcEndpointUrl: APIConfig.tcGetPropertiesUrl(tcUrl: tcURL),
            userUid: tcUserUid
        ) {
            tcUserHomeFolderUid = folderUid
        } else {
            tcErrorMessage = "Could not fetch homefolder UID"
            LoggerHelper.error("getUserHomeFolder returned nil")
        }

        if let folderArray = await tcApi.expandFolder(
            tcUrl: tcURL,
            folderUid: tcUserHomeFolderUid,
            expItemRev: false,
            latestNRevs: -1,
            info: [],
            contentTypesFilter: [],
            propertyAttributes: ["object_name", "object_desc", "creation_date"]
        ) {
            homeFolderContent = folderArray
        } else {
            LoggerHelper.error("expandFolder returned nil or failed")
        }

        isLoading = false
    }
}
