//
//  SettingsManager.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025
//

import Foundation
import Combine
import SwiftUI

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
    //
    private let itemsFolderUidKey = "com.krusty84.settings.itemsFolderUid"
    private let itemsFolderNameKey = "com.krusty84.settings.itemsFolderName"
    private let itemsFolderClassNameKey = "com.krusty84.settings.itemsFolderClassName"
    private let itemsFolderTypeKey = "com.krusty84.settings.itemsFolderType"
    private let itemsListOfTypesKey = "com.krusty84.settings.itemsListOfTypes"
    //
    private let bomFolderUidKey = "com.krusty84.settings.bomFolderUid"
    private let bomFolderNameKey = "com.krusty84.settings.bomFolderName"
    private let bomFolderClassNameKey = "com.krusty84.settings.bomFolderClassName"
    private let bomFolderTypeKey = "com.krusty84.settings.bomFolderType"
    private let bomListOfTypesKey = "com.krusty84.settings.bomListOfTypes"
    //
    private let requirementFolderUidKey = "com.krusty84.settings.settings.requirementFolderUid"
    private let requirementFolderNameKey = "com.krusty84.settings.requirementFolderName"
    private let requirementFolderClassNameKey = "com.krusty84.settings.requirementFolderClassName"
    private let requirementFolderTypeKey = "com.krusty84.settings.requirementFolderType"
    
    
    init() {
        // Load initial data from UserDefaults
        var arrayItemsType = defaults.stringArray(forKey: itemsListOfTypesKey) ?? []
        var arrayBomType = defaults.stringArray(forKey: bomListOfTypesKey) ?? []
        
        // Ensure "Item" exists at index 0
        if !arrayItemsType.contains("Item") {
            arrayItemsType.insert("Item", at: 0)
            defaults.set(arrayItemsType, forKey: itemsListOfTypesKey)
        }
        
        if !arrayBomType.contains("Item") {
            arrayBomType.insert("Item", at: 0)
            defaults.set(arrayBomType, forKey: itemsListOfTypesKey)
        }
        
        self.itemsListOfTypes_storage = arrayItemsType
        self.bomListOfTypes_storage = arrayBomType
    }
    
    // Default prompts
    let defaultItemsPrompt = """
    You are a domain expert who converts industry-specific items into perfect JSON format.
    EXAMPLE INPUT:
    Domain: Automotive
    Count: 2
    EXAMPLE JSON OUTPUT:
    {
        "items": [
            {
                "name": "Turbocharger",
                "desc": "Boosts engine power via forced induction"
            },
            {
                "name": "OBD-II Scanner",
                "desc": "Reads vehicle diagnostic trouble codes"
            }
        ]
    }
    RULES:
    1. Only use actual industry-standard terms
    2. Descriptions must be 5–10 words
    3. Maintain technical accuracy
    ACTUAL TASK:
    Generate a list of real-world items for:
    Domain: {domainName}
    Count: {count}
    """
    let defaultItemsTemperature = 0.5
    let defaultItemsMaxTokens = 1000
    //
    let defaultBOMPrompt = """
    You are an engineering-domain expert who writes Engineering Bills of Material (eBOM) into perfect JSON format.
    EXAMPLE INPUT:
    Product: Turbocharger
    Number of components: 3
    EXAMPLE JSON OUTPUT:
    {
        "product": {
            "name": "Turbocharger",
            "desc": "Boosts engine power via forced induction",
            "items": [
                {
                    "name": "Compressor section",
                    "desc": "Draws and compresses intake air",
                    "items": [
                        {
                            "name": "Compressor wheel",
                            "desc": "Rotating aluminium impeller",
                            "items": []
                        },
                        {
                            "name": "Compressor housing",
                            "desc": "Cast shell guiding airflow",
                            "items": []
                        }
                    ]
                },
                {
                    "name": "Turbine section",
                    "desc": "Uses exhaust gas energy",
                    "items": [
                        {
                            "name": "Turbine wheel",
                            "desc": "High-temp nickel alloy rotor",
                            "items": []
                        },
                        {
                            "name": "Turbine housing",
                            "desc": "Ducts exhaust to wheel",
                            "items": []
                        }
                    ]
                }
            ]
        }
    }
    RULES:
    1. Use only real engineering part names
    2. Each desc is 3–10 simple, accurate words
    3. Keep nesting until Depth is reached
    4. Return exactly one JSON object—no extra text, no comments
    ACTUAL TASK:
    Create the Engineering BOM now for:
    Product: {productName}
    Number of components: {depth}
    """
    let defaultBomTemperature = 0.5
    let defaultBomMaxTokens = 1000
    
    let defaultReqSpecPrompt = "Generate a requirements specification based on the product details."
    let defaultReqSpecTemperature = 0.5
    let defaultReqSpecMaxTokens = 1000
    
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
    var itemsFolderClassName: String {
        get { defaults.string(forKey: itemsFolderClassNameKey) ?? "" }
        set { defaults.set(newValue, forKey: itemsFolderClassNameKey) }
    }
    var itemsFolderType: String {
        get { defaults.string(forKey: itemsFolderTypeKey) ?? "" }
        set { defaults.set(newValue, forKey: itemsFolderTypeKey) }
    }
    
    @Published var itemsListOfTypes_storage: [String] {
        didSet {
            defaults.set(itemsListOfTypes_storage, forKey: itemsListOfTypesKey)
        }
    }
    
    var itemsListOfTypes: Binding<[String]> {
        Binding<[String]>(
            get:  { self.itemsListOfTypes_storage },
            set:  { self.itemsListOfTypes_storage = $0 }
        )
    }
    
    var bomFolderUid: String {
        get { defaults.string(forKey: bomFolderUidKey) ?? "" }
        set { defaults.set(newValue, forKey: bomFolderUidKey) }
    }
    var bomFolderName: String {
        get { defaults.string(forKey: bomFolderNameKey) ?? "" }
        set { defaults.set(newValue, forKey: bomFolderNameKey) }
    }
    var bomFolderClassName: String {
        get { defaults.string(forKey: bomFolderClassNameKey) ?? "" }
        set { defaults.set(newValue, forKey: bomFolderClassNameKey) }
    }
    var bomFolderType: String {
        get { defaults.string(forKey: bomFolderTypeKey) ?? "" }
        set { defaults.set(newValue, forKey: bomFolderTypeKey) }
    }
    
    @Published var bomListOfTypes_storage: [String] {
        didSet {
            defaults.set(bomListOfTypes_storage, forKey: bomListOfTypesKey)
        }
    }
    
    var bomListOfTypes: Binding<[String]> {
        Binding<[String]>(
            get:  { self.bomListOfTypes_storage },
            set:  { self.bomListOfTypes_storage = $0 }
        )
    }
    
    var requirementsFolderUid: String {
        get { defaults.string(forKey: requirementFolderUidKey) ?? "" }
        set { defaults.set(newValue, forKey: requirementFolderUidKey) }
    }
    var requirementsFolderName: String {
        get { defaults.string(forKey: requirementFolderNameKey) ?? "" }
        set { defaults.set(newValue, forKey: requirementFolderNameKey) }
    }
    var requirementsFolderClassName: String {
        get { defaults.string(forKey: requirementFolderClassNameKey) ?? "" }
        set { defaults.set(newValue, forKey: requirementFolderClassNameKey) }
    }
    var requirementsFolderType: String {
        get { defaults.string(forKey: requirementFolderTypeKey) ?? "" }
        set { defaults.set(newValue, forKey: requirementFolderTypeKey) }
    }
}
