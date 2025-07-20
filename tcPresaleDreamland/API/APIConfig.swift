//
//  APIConfig.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import Foundation

struct APIConfig {
    private let settings = SettingsManager.shared
    //
    static let deepSeekChatCcompletions = "https://api.deepseek.com/v1/chat/completions"
    static let deepSeekPlatform = "https://platform.deepseek.com"
    //
    static func awcOpenDataPath(awcUrl: String) -> String {
        return "\(awcUrl)/#/com.siemens.splm.clientfx.tcui.xrt.showObject?uid="
    }
    static func tcLoginUrl(tcUrl: String) -> String {
        return "\(tcUrl)/JsonRestServices/Core-2011-06-Session/login"
    }
    static func tcSessionInfoUrl(tcUrl: String) -> String {
        return "\(tcUrl)/JsonRestServices/Core-2007-01-Session/getTCSessionInfo"
    }
    static func tcGetPropertiesUrl(tcUrl: String) -> String {
        return "\(tcUrl)/JsonRestServices/Core-2006-03-DataManagement/getProperties"
    }
    static func tcExpandFolder(tcUrl: String) -> String {
        return "\(tcUrl)/JsonRestServices/Cad-2008-06-DataManagement/expandFoldersForCAD"
    }
    static func tcCreateItem(tcUrl: String) -> String {
        return "\(tcUrl)/JsonRestServices/Core-2006-03-DataManagement/createItems"
    }
    static func tcCreateFolder(tcUrl: String) -> String {
        return "\(tcUrl)/JsonRestServices/Core-2006-03-DataManagement/createFolders"
    }
    
    static func getItemFromId(tcUrl: String) -> String {
        return "\(tcUrl)/JsonRestServices/Core-2007-01-DataManagement/getItemFromId"
    }
    
    static func createBOMWindows(tcUrl: String) -> String {
        return "\(tcUrl)/JsonRestServices/Cad-2007-01-StructureManagement/createBOMWindows"
    }
    
    static func addOrUpdateBOMLine(tcUrl: String) -> String {
        return "\(tcUrl)/JsonRestServices/Bom-2008-06-StructureManagement/addOrUpdateChildrenToParentLine"
    }
    
    static func saveBOMWindows(tcUrl: String) -> String {
        return "\(tcUrl)/JsonRestServices/Cad-2008-06-StructureManagement/saveBOMWindows"
    }
    
    static func closeBOMWindows(tcUrl: String) -> String {
        return "\(tcUrl)/JsonRestServices/Cad-2007-01-StructureManagement/closeBOMWindows"
    }

}
