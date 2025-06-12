//
//  Teamcenter.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 02/06/2025.
//

import Foundation

// MARK: Codable models for the login response

/// Matches the "serverInfo" object in the login response
struct ServerInfo: Codable {
    let DisplayVersion: String?
    let HostName: String?
    let Locale: String?
    let LogFile: String?
    let SiteLocale: String?
    let TcServerID: String?
    let UserID: String?
    let Version: String?
}

/// Top-level for the login response
struct LoginResponse: Codable {
    let qName: String?            // maps to ".QName"
    let serverInfo: ServerInfo?

    enum CodingKeys: String, CodingKey {
        case qName = ".QName"
        case serverInfo = "serverInfo"
    }
}

struct SessionObject: Codable {
    let objectID: String?       // sometimes missing (e.g. under "user")
    let cParamID: String?       // sometimes missing
    let uid: String
    let className: String
    let type: String
}

typealias ExtraInfo = [String: String]

struct SessionServiceData: Codable {
    let plain: [String]
    let modelObjects: [String: FolderBasic]
}

/// The full response you see in Postman for GetTCSessionInfo
struct SessionInfoResponse: Codable {
    let qName: String?                 // ".QName"
    let serverVersion: String
    let transientVolRootDir: String
    let isInV7Mode: Bool
    let moduleNumber: Int
    let bypass: Bool
    let journaling: Bool
    let appJournaling: Bool
    let secJournaling: Bool
    let admJournaling: Bool
    let privileged: Bool
    let isPartBOMUsageEnabled: Bool
    let isSubscriptionMgrEnabled: Bool

    let user: SessionObject
    let group: SessionObject
    let role: SessionObject
    let tcVolume: SessionObject
    let project: SessionObject
    let workContext: SessionObject
    let site: SessionObject

    let textInfos: [String]
    let extraInfo: ExtraInfo

    let serviceData: SessionServiceData?

    enum CodingKeys: String, CodingKey {
        case qName = ".QName"
        case serverVersion
        case transientVolRootDir
        case isInV7Mode
        case moduleNumber
        case bypass
        case journaling
        case appJournaling
        case secJournaling
        case admJournaling
        case privileged
        case isPartBOMUsageEnabled
        case isSubscriptionMgrEnabled
        case user
        case group
        case role
        case tcVolume
        case project
        case workContext
        case site
        case textInfos
        case extraInfo
        case serviceData = "ServiceData"
    }
}

// MARK: Codable models for expandFolder response

/// 1) Basic folder info (used under "fstlvlFolders" and under "modelObjects")
///    Make objectID optional, because "inputFolder" does not include it.
struct FolderBasic: Codable {
    let objectID: String?
    let uid: String
    let className: String
    let type: String
}

/// 2) Matches one element of the "output" array
struct ExpandFolderOutput: Codable {
    let inputFolder: FolderBasic
    let fstlvlFolders: [FolderBasic]
    // itemsOutput and itemRevsOutput were empty in your example;
    // omit them unless you need to parse them:
    // let itemsOutput: [String]?
    // let itemRevsOutput: [String]?
}

/// 3) Matches "ServiceData" → "plain" and "modelObjects"
struct ExpandServiceData: Codable {
    let plain: [String]
    let modelObjects: [String: FolderBasic]
}

/// 4) Top‐level for expandFolder
struct ExpandFolderResponse: Codable {
    let qName: String?                   // maps to ".QName"
    let output: [ExpandFolderOutput]?
    let serviceData: ExpandServiceData?

    enum CodingKeys: String, CodingKey {
        case qName = ".QName"
        case output
        case serviceData = "ServiceData"
    }
}

// MARK: Codable models for getProperties response

/// Each property under "props" has dbValues and uiValues
struct PropertyValue: Codable {
    let dbValues: [String]?
    let uiValues: [String]?
}

/// Matches one entry under "modelObjects" in getProperties
struct ModelObject: Codable {
    let objectID: String?
    let uid: String?
    let className: String?
    let type: String?
    let props: [String: PropertyValue]?
}

/// Top‐level for getProperties
struct GetPropertiesResponse: Codable {
    let qName: String?                  // maps to ".QName"
    let plain: [String]?
    let modelObjects: [String: ModelObject]?

    enum CodingKeys: String, CodingKey {
        case qName = ".QName"
        case plain
        case modelObjects
    }
}

// MARK: Codable models for createItem (only what we need)

/// We only need the nested item and itemRev objects
struct CreateItemsOutput: Codable {
    struct NestedObject: Codable {
        let uid: String
    }
    let item: NestedObject
    let itemRev: NestedObject
}

/// Top‐level for CreateItems, decoding only “output”
struct CreateItemsResponse: Codable {
    let output: [CreateItemsOutput]?

    enum CodingKeys: String, CodingKey {
        case output
    }
}

// MARK: Codable models for createFolder response

/// We only need the nested “folder” object
struct CreateFoldersOutput: Codable {
    struct FolderObj: Codable {
        let uid: String
        let className: String
        let type: String
    }
    let folder: FolderObj
}

/// Top‐level for CreateFolders
struct CreateFoldersResponse: Codable {
    let output: [CreateFoldersOutput]?

    enum CodingKeys: String, CodingKey {
        case output
    }
}
