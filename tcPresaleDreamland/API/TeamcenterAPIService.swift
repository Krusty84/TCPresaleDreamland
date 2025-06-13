//
//  TeamcenterAPIService.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 01/06/2025.
//

import Foundation
import Combine

class TeamcenterAPIService: ObservableObject {
    static let shared = TeamcenterAPIService()
    private let tcHelpers = TCHelpers.shared
    // This will hold the JSESSIONID string after a successful login
    @Published var jsessionId: String? = nil
    
    private init() {}
    
    func tcLogin(
        tcEndpointUrl: String,
        userName: String,
        userPassword: String
    ) async -> String? {
        // 1. Build URL
        guard let url = URL(string: tcEndpointUrl) else {
            print("Invalid URL:", tcEndpointUrl)
            return nil
        }
        
        // 2. Build payload exactly as Teamcenter needs
        let payload: [String: Any] = [
            "header": ["state": [:], "policy": [:]],
            "body": [
                "credentials": [
                    "user": userName,
                    "password": userPassword,
                    "role": "",
                    "descrimator": "",
                    "locale": "",
                    "group": ""
                ]
            ]
        ]
        
        // 3. JSON-encode the payload
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("Could not encode JSON:", error)
            return nil
        }
        
        // 4. Build the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            // 5. Send it
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                print("Not an HTTP response")
                return nil
            }
            
            // 6. Parse JSON body into a Dictionary
            guard
                let jsonObj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let qName = jsonObj[".QName"] as? String
            else {
                print("Bad JSON or missing .QName")
                return nil
            }
            
            // 7. Check if it’s the login response or an exception
            if qName.contains("Session.LoginResponse") {
                // success
            } else {
                // failure: show the message if any
                if let msg = jsonObj["message"] as? String {
                    print("Login error from server:", msg)
                } else {
                    print("Login failed with exception:", qName)
                }
                return nil
            }
            
            // 8. Try to grab a new JSESSIONID cookie
            if let cookieHeader = http.value(forHTTPHeaderField: "Set-Cookie") {
                let parts = cookieHeader
                    .split(separator: ";")
                    .map(String.init)
                if let jsPart = parts.first(where: { $0.hasPrefix("JSESSIONID=") }),
                   let newID = jsPart.split(separator: "=").last
                {
                    let session = String(newID)
                    DispatchQueue.main.async {
                        self.jsessionId = session
                    }
                    print("Got new JSESSIONID:", session)
                    return session
                }
            }
            
            // 9. No new cookie – but status 2xx means login still good
            if (200...299).contains(http.statusCode),
               let old = self.jsessionId
            {
                print("Reusing old JSESSIONID:", old)
                return old
            }
            
            // 10. If we get here, something unexpected happened
            print("Login got status \(http.statusCode) but no session")
            return nil
            
        } catch {
            print("Network or JSON error:", error)
            return nil
        }
    }

    
    func getTcSessionInfo(tcEndpointUrl: String) async -> SessionInfoResponse? {
        // 1) Ensure we have a JSESSIONID from a prior login
        guard let session = self.jsessionId else {
            print("No JSESSIONID found. Please login first.")
            return nil
        }
        
        // 2) Validate the URL
        guard let url = URL(string: tcEndpointUrl) else {
            print("Invalid URL string: \(tcEndpointUrl)")
            return nil
        }
        
        // 3) Prepare payload with only header (empty state & policy)
        let payload: [String: Any] = [
            "header": [
                "state": [:],
                "policy": [:]
            ]
        ]
        
        // 4) Serialize that minimal payload to Data
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Failed to serialize JSON payload for session info:", error)
            return nil
        }
        
        // 5) Build URLRequest with Cookie header
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //    Attach the existing JSESSIONID as a Cookie
        request.setValue("JSESSIONID=\(session)", forHTTPHeaderField: "Cookie")
        request.httpBody = jsonData
        
        do {
            // 6) Execute the request
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("No HTTPURLResponse when fetching session info.")
                return nil
            }
            
            // 7) Check for HTTP 2xx status
            guard (200...299).contains(httpResponse.statusCode) else {
                print("Failed to fetch session info. HTTP status:", httpResponse.statusCode)
                return nil
            }
            
            // 8) Decode JSON into SessionInfoResponse via Codable
            let decoder = JSONDecoder()
            do {
                let sessionInfo = try decoder.decode(SessionInfoResponse.self, from: data)
                return sessionInfo
            } catch {
                print("Could not decode JSON for session info:", error)
                return nil
            }
            
        } catch {
            print("Network error during session info request:", error)
            return nil
        }
    }
    
    func getProperties(
        tcEndpointUrl: String,
        uid: String,
        className: String,
        type: String,
        attributes: [String]
    ) async -> [String: String]? {
        // 1a) Make sure JSESSIONID is set
        guard let session = self.jsessionId else {
            print("Cannot call getProperties: no JSESSIONID stored. Please login first.")
            return nil
        }
        
        // 1b) Build URL
        guard let url = URL(string: tcEndpointUrl) else {
            print("Invalid getProperties URL: \(tcEndpointUrl)")
            return nil
        }
        
        // 1c) Build the single-object dictionary
        let objectEntry: [String: String] = [
            "uid": uid,
            "className": className,
            "type": type
        ]
        
        // 1d) Build the JSON payload
        let payload: [String: Any] = [
            "header": [
                "state": [:],
                "policy": [:]
            ],
            "body": [
                "objects": [objectEntry],
                "attributes": attributes
            ]
        ]
        
        // 1e) Serialize to Data
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Failed to serialize JSON for getProperties: \(error)")
            return nil
        }
        
        // 1f) Build POST request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("JSESSIONID=\(session)", forHTTPHeaderField: "Cookie")
        request.httpBody = jsonData
        
        do {
            // 1g) Execute network call
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("getProperties did not return an HTTPURLResponse.")
                return nil
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                print("getProperties failed. HTTP status = \(httpResponse.statusCode).")
                return nil
            }
            
            // 1h) Decode JSON via Codable
            let decoder = JSONDecoder()
            let responseObj = try decoder.decode(GetPropertiesResponse.self, from: data)
            
            // 1i) Look up our single ModelObject by UID
            guard
                let modelDict = responseObj.modelObjects,
                let singleObj = modelDict[uid],
                let allProps = singleObj.props
            else {
                print("No modelObjects or props found for UID \(uid).")
                return nil
            }
            
            // 1j) Build a dictionary [attributeName: firstUiValue]
            var result: [String: String] = [:]
            for attr in attributes {
                if let propValue = allProps[attr],
                   let firstUi = propValue.uiValues?.first {
                    result[attr] = firstUi
                } else {
                    // No value found → empty string
                    result[attr] = ""
                }
            }
            return result
            
        } catch {
            print("Network or decoding error during getProperties: \(error)")
            return nil
        }
    }
    
    func getUserHomeFolder(
        tcEndpointUrl: String,
        userUid: String
    ) async -> String? {
        // 1) Make sure we have a stored JSESSIONID
        guard let session = self.jsessionId else {
            print("No JSESSIONID found. Please login first.")
            return nil
        }
        
        // 2) Build the endpoint URL
        guard let url = URL(string: tcEndpointUrl) else {
            print("Invalid URL string: \(tcEndpointUrl)")
            return nil
        }
        
        // 3) Build the exact payload for fetching "home_folder"
        let payload: [String: Any] = [
            "header": [
                "state": [:],
                "policy": [:]
            ],
            "body": [
                "objects": [[
                    "uid": userUid,
                    "className": "User",
                    "type": "User"
                ]],
                // We only request the "home_folder" attribute
                "attributes": ["home_folder"]
            ]
        ]
        
        // 4) Serialize payload to JSON data
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Failed to serialize JSON for getUserHomeFolder: \(error)")
            return nil
        }
        
        // 5) Create and send the POST request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Attach the JSESSIONID cookie
        request.setValue("JSESSIONID=\(session)", forHTTPHeaderField: "Cookie")
        request.httpBody = jsonData
        
        do {
            // 6) Execute the network call
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("getUserHomeFolder did not return an HTTPURLResponse.")
                return nil
            }
            
            // 7) Check for an HTTP 2xx status
            guard (200...299).contains(httpResponse.statusCode) else {
                print("getUserHomeFolder failed. HTTP status =", httpResponse.statusCode)
                return nil
            }
            
            // 8) Decode the JSON into our Codable model
            let decoder = JSONDecoder()
            let respObj = try decoder.decode(GetPropertiesResponse.self, from: data)
            
            // 9) Find the single ModelObject for our userUid
            guard
                let modelDict = respObj.modelObjects,
                let userObj = modelDict[userUid],
                let props = userObj.props
            else {
                print("No modelObjects or props found for user UID \(userUid).")
                return nil
            }
            
            // 10) Look up the "home_folder" entry and return its first UI value
            if let homeVal = props["home_folder"]?.dbValues?.first {
                return homeVal
            } else {
                print("\"home_folder\" not found or has no uiValues.")
                return nil
            }
            
        } catch {
            print("Network or decoding error during getUserHomeFolder:", error)
            return nil
        }
    }
    
    func expandFolder(
        tcUrl: String,
        folderUid: String,
        className: String = "Folder",
        type: String = "Fnd0HomeFolder",
        expItemRev: Bool,
        latestNRevs: Int,
        info: [[String: Any]],
        contentTypesFilter: [String],
        propertyAttributes: [String]
    ) async -> [[String: Any]]? {
        // 2a) Ensure JSESSIONID is set
        guard let session = self.jsessionId else {
            print("Cannot call expandFolder: no JSESSIONID stored. Please login first.")
            return nil
        }
        
        // 2b) Build the two endpoint URLs
        let expandUrlString = APIConfig.tcExpandFolder(tcUrl: tcUrl)
        let propsUrlString = APIConfig.tcGetPropertiesUrl(tcUrl: tcUrl)
        
        guard
            let expandUrl = URL(string: expandUrlString),
            URL(string: propsUrlString) != nil
        else {
            print("Invalid expandFolder or getProperties URL.")
            return nil
        }
        
        // 2c) Build the single-folder entry
        let folderEntry: [String: String] = [
            "uid": folderUid,
            "className": className,
            "type": type
        ]
        
        // 2d) Build the "pref" dictionary
        let pref: [String: Any] = [
            "expItemRev": expItemRev,
            "latestNRevs": latestNRevs,
            "info": info,
            "contentTypesFilter": contentTypesFilter
        ]
        
        // 2e) Compose the full JSON payload for expandFolder
        let expandPayload: [String: Any] = [
            "header": [
                "state": [:],
                "policy": [:]
            ],
            "body": [
                "folders": [folderEntry],
                "pref": pref
            ]
        ]
        
        // 2f) Serialize that payload to Data
        let expandData: Data
        do {
            expandData = try JSONSerialization.data(withJSONObject: expandPayload, options: [])
        } catch {
            print("Failed to serialize JSON for expandFolder: \(error)")
            return nil
        }
        
        // 2g) Build and send the expandFolder POST request
        var expandRequest = URLRequest(url: expandUrl)
        expandRequest.httpMethod = "POST"
        expandRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        expandRequest.setValue("JSESSIONID=\(session)", forHTTPHeaderField: "Cookie")
        expandRequest.httpBody = expandData
        
        // 2h) Perform the network call
        let responseData: Data
        do {
            let (data, response) = try await URLSession.shared.data(for: expandRequest)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                print("expandFolder failed. HTTP status not 2xx.")
                return nil
            }
            responseData = data
        } catch {
            print("Network or decoding error during expandFolder: \(error)")
            return nil
        }
        
        // 2i) Decode the expandFolder JSON via Codable
        let decoder = JSONDecoder()
        let expandResponseObj: ExpandFolderResponse
        do {
            expandResponseObj = try decoder.decode(ExpandFolderResponse.self, from: responseData)
        } catch {
            print("Failed to decode expandFolder JSON: \(error)")
            return nil
        }
        
        // 2j) Extract “serviceData” and then its “modelObjects”
        guard let serviceData = expandResponseObj.serviceData else {
            print("No \"ServiceData\" in expandFolder response.")
            return nil
        }
        // modelObjects is non-optional ([String: FolderBasic]) by our Codable definition
        let modelObjects = serviceData.modelObjects
        
        // 2k) Prepare the array we will return
        var finalResults: [[String: Any]] = []
        
        // 2l) For each entry in modelObjects (key is UID, value is FolderBasic)
        for (_, folderInfo) in modelObjects {
            // 2l-i) Use folderInfo.className, type, uid directly (non-optional)
            let cls = folderInfo.className
            let typ = folderInfo.type
            let uid = folderInfo.uid
            
            // 2l-ii) Call getProperties(...) to fetch this folder’s properties
            guard
                let parsedProps = await getProperties(
                    tcEndpointUrl: propsUrlString,
                    uid: uid,
                    className: cls,
                    type: typ,
                    attributes: propertyAttributes
                )
            else {
                // If getProperties failed, skip this object
                continue
            }
            
            // 2l-iii) Build one dictionary containing:
            //            - "uid", "className", "type"
            //            - each requested attribute → its first UI value
            var resultEntry: [String: Any] = [
                "uid": uid,
                "className": cls,
                "type": typ
            ]
            for (attrName, uiValue) in parsedProps {
                resultEntry[attrName] = uiValue
            }
            
            // 2l-iv) Append to our final array
            finalResults.append(resultEntry)
        }
        
        // 2m) Return the array of dictionaries
        return finalResults
    }
    
    func createItem(
        tcEndpointUrl: String,
        name: String,
        type: String,
        description: String,
        containerUid: String,
        containerClassName: String,
        containerType: String
    ) async -> (itemUid: String?, itemRevUid: String?) {
        // 1. Ensure we have a session cookie
        guard let session = jsessionId else {
            print("No JSESSIONID—login first.")
            return (nil, nil)
        }
        
        // 2. Build URL
        guard let url = URL(string: tcEndpointUrl) else {
            print("Bad URL:", tcEndpointUrl)
            return (nil, nil)
        }
        
        // 3. Build payload
        let payload: [String: Any] = [
            "header": ["state": [:], "policy": [:]],
            "body": [
                "properties": [[
                    "clientId": "",
                    "itemId": "",
                    "name": name,
                    "type": type,
                    "revId": "",
                    "uom": "",
                    "description": description,
                    "extendedAttributes": []
                ]],
                "container": [
                    "uid": containerUid,
                    "className": containerClassName,
                    "type": containerType
                ],
                "relationType": ""
            ]
        ]
        
        // 4. Serialize JSON
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("JSON error:", error)
            return (nil, nil)
        }
        
        // 5. Create request
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("JSESSIONID=\(session)", forHTTPHeaderField: "Cookie")
        req.httpBody = jsonData
        
        do {
            // 6. Send and check status
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                print("HTTP error:", resp)
                return (nil, nil)
            }
            
            // 7. Decode only "output"
            let decoder = JSONDecoder()
            let createResp = try decoder.decode(CreateItemsResponse.self, from: data)
            if let first = createResp.output?.first {
                return (first.item.uid, first.itemRev.uid)
            } else {
                print("No output in response")
                return (nil, nil)
            }
            
        } catch {
            print("Network/decode error:", error)
            return (nil, nil)
        }
    }
    
 
    func createFolder(
            tcEndpointUrl: String,
            name: String,
            desc: String,
            containerUid: String,
            containerClassName: String,
            containerType: String
    ) async -> (uid: String?, className: String?, type: String?) {
        // 1. Make sure we have a session cookie
        guard let session = jsessionId else {
            print("No JSESSIONID—please login first.")
            return (nil, nil, nil)
        }

        // 2. Build the endpoint URL
        guard let url = URL(string: tcEndpointUrl) else {
            print("Invalid URL:", tcEndpointUrl)
            return (nil, nil, nil)
        }

        // 3. Build the JSON payload
        let payload: [String: Any] = [
            "header": ["state": [:], "policy": [:]],
            "body": [
                "folders": [[
                    "clientId": "",
                    "name": name,
                    "desc": desc
                ]],
                "container": [
                    "uid": containerUid,
                    "className": containerClassName,
                    "type": containerType
                ],
                "relationType": "contents"
            ]
        ]

        // 4. Serialize to JSON data
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("JSON serialization error:", error)
            return (nil, nil, nil)
        }

        // 5. Create and send the POST request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("JSESSIONID=\(session)", forHTTPHeaderField: "Cookie")
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                    (200...299).contains(http.statusCode) else {
                print("HTTP error creating folder:", response)
                return (nil, nil, nil)
            }

            // 6. Decode only the "output" array
            let decoder = JSONDecoder()
            let resp = try decoder.decode(CreateFoldersResponse.self, from: data)

            // 7. Pull out the first folder entry
            if let first = resp.output?.first?.folder {
                return (first.uid, first.className, first.type)
            } else {
                print("No folder info in response.")
                return (nil, nil, nil)
            }

        } catch {
            print("Network or decode error in createFolder:", error)
            return (nil, nil, nil)
        }
    }
    

}
