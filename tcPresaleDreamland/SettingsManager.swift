//
//  SettingsManager.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025
//

import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    private let defaults = UserDefaults.standard
    
    private let appLoggingEnabledKey = "com.krusty84.settings.appLoggingEnabled"
    private let apiKeyKey = "com.krusty84.settings.apiKey"
    private let bomPromptKey = "com.krusty84.settings.bomPrompt"
    private let bomTemperatureKey = "com.krusty84.settings.bomTemperature"
    private let bomMaxTokensKey = "com.krusty84.settings.bomMaxTokens"
    private let reqSpecPromptKey = "com.krusty84.settings.reqSpecPrompt"
    private let reqSpecTemperatureKey = "com.krusty84.settings.reqSpecTemperature"
    private let reqSpecMaxTokensKey = "com.krusty84.settings.reqSpecMaxTokens"
    private let itemsPromptKey = "com.krusty84.settings.itemsPrompt"
    private let itemsTemperatureKey = "com.krusty84.settings.itemsTemperature"
    private let itemsMaxTokensKey = "com.krusty84.settings.itemsMaxTokens"
    private let tcURLKey = "com.krusty84.settings.tcURL"
    private let awcURLKey = "com.krusty84.settings.awcURL"
    private let tcUsernameKey = "com.krusty84.settings.tcUsername"
    private let tcPasswordKey = "com.krusty84.settings.tcPassword"
    private let tcUserUidKey = "com.krusty84.settings.tcUserUid"
    private let tcUserHomeFolderUidKey = "com.krusty84.settings.tcUserHomeFolderUid"
    private let itemsFolderUidKey = "com.krusty84.settings.itemsFolderUid"
    private let itemsFolderNameKey = "com.krusty84.settings.itemsFolderName"
    private let bomsFolderUidKey = "com.krusty84.settings.bomsFolderUid"
    private let bomsFolderNameKey = "com.krusty84.settings.bomsFolderName"
    private let requirementsFolderUidKey = "com.krusty84.settings.settings.requirementsFolderUid"
    private let requirementsFolderNameKey = "com.krusty84.settings.requirementsFolderName"


    // Default prompts
    let defaultBOMPrompt = """
    Generate a Bill of Materials (BOM) for the specified product: [PRODUCT_NAME]. Return the BOM as a JSON object with the following structure: 
    {
      "product": "[PRODUCT_NAME]",
      "components": [
        {
          "part_name": string,
          "part_number": string,
          "quantity": number,
          "material": string,
          "description": string,
          "supplier": string (optional)
        }
      ]
    }
    Ensure all components necessary for the assembly of [PRODUCT_NAME] are listed comprehensively.
    """
    let defaultBomTemperature = 0.5
    let defaultBomMaxTokens = 1000

    let defaultReqSpecPrompt = "Generate a requirements specification based on the product details."
    let defaultReqSpecTemperature = 0.5
    let defaultReqSpecMaxTokens = 1000
    
    let defaultItemsPrompt = "Generate item entries from the provided list."
    let defaultItemsTemperature = 0.5
    let defaultItemsMaxTokens = 1000
    
    var appLoggingEnabled: Bool {
        get { defaults.bool(forKey: appLoggingEnabledKey) }
        set { defaults.set(newValue, forKey: appLoggingEnabledKey) }
    }
    
    var apiKey: String {
        get { defaults.string(forKey: apiKeyKey) ?? "" }
        set { defaults.set(newValue, forKey: apiKeyKey) }
    }
    
    var bomPrompt: String {
        get { defaults.string(forKey: bomPromptKey) ?? defaultBOMPrompt }
        set { defaults.set(newValue, forKey: bomPromptKey) }
    }
    
    var bomTemperature: Double {
        get {
            defaults.object(forKey: bomTemperatureKey) as? Double ?? defaultBomTemperature
        }
        set {
            defaults.set(newValue, forKey: bomTemperatureKey)
        }
    }
    
    var bomMaxTokens: Int {
        get {
            defaults.object(forKey: bomMaxTokensKey) as? Int ?? defaultBomMaxTokens
        }
        set {
            defaults.set(newValue, forKey: bomMaxTokensKey)
        }
    }
    
    var reqSpecPrompt: String {
        get { defaults.string(forKey: reqSpecPromptKey) ?? defaultReqSpecPrompt }
        set { defaults.set(newValue, forKey: reqSpecPromptKey) }
    }
    
    var reqSpecTemperature: Double {
        get { defaults.object(forKey: reqSpecTemperatureKey) as? Double ?? defaultReqSpecTemperature }
        set { defaults.set(newValue, forKey: reqSpecTemperatureKey) }
    }

    var reqSpecMaxTokens: Int {
        get { defaults.object(forKey: reqSpecMaxTokensKey) as? Int ?? defaultReqSpecMaxTokens }
        set { defaults.set(newValue, forKey: reqSpecMaxTokensKey) }
    }
    
    var itemsPrompt: String {
        get { defaults.string(forKey: itemsPromptKey) ?? defaultItemsPrompt }
        set { defaults.set(newValue, forKey: itemsPromptKey) }
    }
    
    var itemsTemperature: Double {
        get { defaults.object(forKey: itemsTemperatureKey) as? Double ?? defaultItemsTemperature }
        set { defaults.set(newValue, forKey: itemsTemperatureKey) }
    }

    var itemsMaxTokens: Int {
        get { defaults.object(forKey: itemsMaxTokensKey) as? Int ?? defaultItemsMaxTokens }
        set { defaults.set(newValue, forKey: itemsMaxTokensKey) }
    }
    
    var tcURL: String {
        get { defaults.string(forKey: tcURLKey) ?? "" }
        set { defaults.set(newValue, forKey: tcURLKey) }
    }
    
    var awcURL: String {
        get { defaults.string(forKey: awcURLKey) ?? "" }
        set { defaults.set(newValue, forKey: awcURLKey) }
    }
    
    var tcUsername: String {
        get { defaults.string(forKey: tcUsernameKey) ?? "" }
        set { defaults.set(newValue, forKey: tcUsernameKey) }
    }
    
    var tcPassword: String {
        get { defaults.string(forKey: tcPasswordKey) ?? "" }
        set { defaults.set(newValue, forKey: tcPasswordKey) }
    }
    
    var tcUserUid: String {
        get { defaults.string(forKey: tcUserUidKey) ?? "" }
        set { defaults.set(newValue, forKey: tcUserUidKey) }
    }
    
    var tcUserHomeFolderUid: String {
        get { defaults.string(forKey: tcUserHomeFolderUidKey) ?? "" }
        set { defaults.set(newValue, forKey: tcUserHomeFolderUidKey) }
    }
    
    var itemsFolderUid: String {
        get { defaults.string(forKey: itemsFolderUidKey) ?? "" }
        set { defaults.set(newValue, forKey: itemsFolderUidKey) }
    }
    var itemsFolderName: String {
        get { defaults.string(forKey: itemsFolderNameKey) ?? "" }
        set { defaults.set(newValue, forKey: itemsFolderNameKey) }
    }

    // UID and Name for "BOM's"
    var bomsFolderUid: String {
        get { defaults.string(forKey: bomsFolderUidKey) ?? "" }
        set { defaults.set(newValue, forKey: bomsFolderUidKey) }
    }
    var bomsFolderName: String {
        get { defaults.string(forKey: bomsFolderNameKey) ?? "" }
        set { defaults.set(newValue, forKey: bomsFolderNameKey) }
    }
    
    var requirementsFolderUid: String {
        get { defaults.string(forKey: requirementsFolderUidKey) ?? "" }
        set { defaults.set(newValue, forKey: requirementsFolderUidKey) }
    }
    var requirementsFolderName: String {
        get { defaults.string(forKey: requirementsFolderNameKey) ?? "" }
        set { defaults.set(newValue, forKey: requirementsFolderNameKey) }
    }
}
