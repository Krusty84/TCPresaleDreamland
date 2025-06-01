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
    private let reqSpecPromptKey = "com.krusty84.settings.reqSpecPrompt"
    private let itemsPromptKey = "com.krusty84.settings.itemsPrompt"
    private let tcURLKey = "com.krusty84.settings.tcURL"
    private let awcURLKey = "com.krusty84.settings.awcURL"
    private let tcUsernameKey = "com.krusty84.settings.tcUsername"
    private let tcPasswordKey = "com.krusty84.settings.tcPassword"

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
    let defaultReqSpecPrompt = "Generate a requirements specification based on the product details."
    let defaultItemsPrompt = "Generate item entries from the provided list."

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

    var reqSpecPrompt: String {
        get { defaults.string(forKey: reqSpecPromptKey) ?? defaultReqSpecPrompt }
        set { defaults.set(newValue, forKey: reqSpecPromptKey) }
    }

    var itemsPrompt: String {
        get { defaults.string(forKey: itemsPromptKey) ?? defaultItemsPrompt }
        set { defaults.set(newValue, forKey: itemsPromptKey) }
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
}
