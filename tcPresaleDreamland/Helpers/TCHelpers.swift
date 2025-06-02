//
//  TCHelpers.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 02/06/2025.
//

import Foundation
import Combine

class TCHelpers: ObservableObject {
    static let shared = TCHelpers()
    private init() { }
    
    /// Given a JSON dictionary, return the user UID.
    ///
    /// - Tries the old format: user.dbValues first.
    /// - If no dbValues, tries the new format: user.uid directly.
    /// - Returns nil if neither is found.
    func getUserUID(from jsonObject: [String: Any]) -> String {
        guard let userDict = jsonObject["user"] as? [String: Any] else {
            return ""  // or return some sentinel value
        }
        if let dbArray = userDict["dbValues"] as? [Any],
           let firstValue = dbArray.first as? String {
            return firstValue
        }
        if let directUID = userDict["uid"] as? String {
            return directUID
        }
        return ""
    }
    
    func getHomeUserFolderUid(from jsonObject: [String: Any]) -> String {
            // 1. Get the "plain" array and take its first element as the user key
            guard
                let plainArray = jsonObject["plain"] as? [Any],
                let userKey = plainArray.first as? String
            else {
                return ""
            }

            // 2. Look up the user object inside "modelObjects"
            guard
                let modelObjects = jsonObject["modelObjects"] as? [String: Any],
                let userObject = modelObjects[userKey] as? [String: Any]
            else {
                return ""
            }

            // 3. Inside that user object, look for "props" → "home_folder"
            guard
                let props = userObject["props"] as? [String: Any],
                let homeFolderDict = props["home_folder"] as? [String: Any]
            else {
                return ""
            }

            // 4. Finally, read "dbValues" and return its first string
            guard
                let dbValues = homeFolderDict["dbValues"] as? [Any],
                let firstHomeUID = dbValues.first as? String
            else {
                return ""
            }

            return firstHomeUID
        }
    
     func parsePropertiesResponse(_ rawJson: [String: Any]) -> [String: String]? {
         print("RAW: ", rawJson)
         var result: [String: String] = [:]

         // Navigate to "modelObjects" dictionary
         guard
             let modelObjects = rawJson["modelObjects"] as? [String: Any],
             let firstEntry = modelObjects.values.first as? [String: Any],
             let props = firstEntry["props"] as? [String: Any]
         else {
             return nil
         }

         // Iterate over each property in "props"
         for (propName, propValue) in props {
             guard
                 let propDict = propValue as? [String: Any],
                 let uiValues = propDict["uiValues"] as? [Any],
                 let firstUI = uiValues.first as? String
             else {
                 continue
             }
             result[propName] = firstUI
         }

         return result
     }
}



