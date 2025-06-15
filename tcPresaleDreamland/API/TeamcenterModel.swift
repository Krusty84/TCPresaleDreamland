//
//  Teamcenter.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 02/06/2025.
//

import Foundation

// MARK: Codable models for the login response

/// Holds server info fields from login response
struct ServerInfo: Codable {
    let DisplayVersion: String?  // Version display string
    let HostName: String?        // Server host name
    let Locale: String?          // Server locale code
    let LogFile: String?         // Path to server log file
    let SiteLocale: String?      // Locale for the site
    let TcServerID: String?      // Teamcenter server ID
    let UserID: String?          // Logged-in user ID
    let Version: String?         // Server version number
}

/// Top-level login response with QName and serverInfo
struct LoginResponse: Codable {
    let qName: String?           // XML QName value
    let serverInfo: ServerInfo?  // Server information

    enum CodingKeys: String, CodingKey {
        case qName = ".QName"    // Map JSON field ".QName"
        case serverInfo = "serverInfo"
    }
}

/// Represents a session object with IDs and type info
struct SessionObject: Codable {
    let objectID: String?   // Optional object identifier
    let cParamID: String?   // Optional parameter ID
    let uid: String         // Unique ID
    let className: String   // Class name of object
    let type: String        // Object type string
}

typealias ExtraInfo = [String: String]  // Simple key-value extra info

/// Service data includes plain strings and basic folder models
struct SessionServiceData: Codable {
    let plain: [String]                       // Plain text entries
    let modelObjects: [String: FolderBasic]   // FolderBasic models by UID
}

/// Full response for GetTCSessionInfo API call
struct SessionInfoResponse: Codable {
    let qName: String?                 // XML QName
    let serverVersion: String          // Version of server
    let transientVolRootDir: String    // Root directory for transients
    let isInV7Mode: Bool               // Mode flag
    let moduleNumber: Int              // Module number
    let bypass: Bool                   // Bypass setting
    let journaling: Bool               // Journaling enabled
    let appJournaling: Bool            // App journaling
    let secJournaling: Bool            // Security journaling
    let admJournaling: Bool            // Admin journaling
    let privileged: Bool               // Privileged session flag
    let isPartBOMUsageEnabled: Bool    // BOM part usage
    let isSubscriptionMgrEnabled: Bool // Subscription manager

    // Main session objects for user, group, role, etc.
    let user: SessionObject
    let group: SessionObject
    let role: SessionObject
    let tcVolume: SessionObject
    let project: SessionObject
    let workContext: SessionObject
    let site: SessionObject

    let textInfos: [String]            // Text info entries
    let extraInfo: ExtraInfo           // Extra key-value pairs
    let serviceData: SessionServiceData? // Optional service data

    enum CodingKeys: String, CodingKey {
        case qName = ".QName"
        case serverVersion, transientVolRootDir, isInV7Mode, moduleNumber
        case bypass, journaling, appJournaling, secJournaling, admJournaling
        case privileged, isPartBOMUsageEnabled, isSubscriptionMgrEnabled
        case user, group, role, tcVolume, project, workContext, site
        case textInfos, extraInfo
        case serviceData = "ServiceData"
    }
}

// MARK: Codable models for expandFolder response

/// Basic info for a folder, may be in first level or modelObjects
struct FolderBasic: Codable {
    let objectID: String? // Optional ID if present
    let uid: String       // Unique identifier
    let className: String // Class name string
    let type: String      // Object type
}

/// One element of "output" array from expandFolder API
struct ExpandFolderOutput: Codable {
    let inputFolder: FolderBasic     // The folder we expanded
    let fstlvlFolders: [FolderBasic] // Subfolders at first level
    // itemsOutput and itemRevsOutput can be added if needed
}

/// ServiceData for expandFolder with plain entries and modelObjects
struct ExpandServiceData: Codable {
    let plain: [String]                        // Plain text entries
    let modelObjects: [String: FolderBasic]    // FolderBasic models by UID
}

/// Top-level response for expandFolder API
struct ExpandFolderResponse: Codable {
    let qName: String?                      // XML QName
    let output: [ExpandFolderOutput]?       // Expand output list
    let serviceData: ExpandServiceData?     // Service data

    enum CodingKeys: String, CodingKey {
        case qName = ".QName"
        case output
        case serviceData = "ServiceData"
    }
}

// MARK: Codable models for getProperties response

/// Holds database and UI values for one property
struct PropertyValue: Codable {
    let dbValues: [String]?  // Raw database values
    let uiValues: [String]?  // Formatted UI values
}

/// One model object entry in getProperties response
struct ModelObject: Codable {
    let objectID: String?                // Optional object ID
    let uid: String?                     // Unique ID
    let className: String?               // Class name
    let type: String?                    // Object type
    let props: [String: PropertyValue]?  // Property values by name
}

/// Top-level response for getProperties API
struct GetPropertiesResponse: Codable {
    let qName: String?                          // XML QName
    let plain: [String]?                        // Plain text entries
    let modelObjects: [String: ModelObject]?    // ModelObject entries by UID

    enum CodingKeys: String, CodingKey {
        case qName = ".QName"
        case plain, modelObjects
    }
}

// MARK: Codable models for createItem response

/// Output for createItem API: nested item and revision
struct CreateItemsOutput: Codable {
    struct NestedObject: Codable {
        let uid: String  // UID of created item or revision
    }
    let item: NestedObject    // Created item
    let itemRev: NestedObject // Created item revision
}

/// Top-level for createItem API
struct CreateItemsResponse: Codable {
    let output: [CreateItemsOutput]?  // List of created outputs

    enum CodingKeys: String, CodingKey {
        case output
    }
}

// MARK: Codable models for createFolder response

/// Output for createFolder API: nested folder object
struct CreateFoldersOutput: Codable {
    struct FolderObj: Codable {
        let uid: String      // UID of new folder
        let className: String // Class name of folder
        let type: String     // Object type string
    }
    let folder: FolderObj   // Created folder object
}

/// Top-level for createFolder API
struct CreateFoldersResponse: Codable {
    let output: [CreateFoldersOutput]?  // List of created folders

    enum CodingKeys: String, CodingKey {
        case output
    }
}
