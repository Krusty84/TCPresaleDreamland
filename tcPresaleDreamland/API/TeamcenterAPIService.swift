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
            // 1) Build the URL
            guard let url = URL(string: tcEndpointUrl) else {
                print("Invalid URL string:", tcEndpointUrl)
                return nil
            }

            // 2) Prepare JSON payload exactly as Teamcenter expects
            let payload: [String: Any] = [
                "header": [
                    "state": [:],
                    "policy": [:]
                ],
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

            // 3) Serialize payload to Data
            let jsonData: Data
            do {
                jsonData = try JSONSerialization.data(
                    withJSONObject: payload,
                    options: []
                )
            } catch {
                print("Failed to serialize JSON payload:", error)
                return nil
            }

            // 4) Build URLRequest
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            do {
                // 5) Perform the network call
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("No HTTP response (not an HTTPURLResponse).")
                    return nil
                }

                // 6) Decode the JSON response body via Codable
                let decoder = JSONDecoder()
                do {
                    let loginResp = try decoder.decode(LoginResponse.self, from: data)
                    // (We could inspect loginResp.qName or loginResp.serverInfo here
                    //  if we wanted to verify a successful login.)
                    // For now, we just ignore them because our goal is the JSESSIONID.
                } catch {
                    print("Failed to decode login response JSON:", error)
                    // Even if decoding fails, we might still get a Set-Cookie header below.
                    // So we do not return nil here—let’s still try to parse Set-Cookie.
                }

                // 7) Try to parse JSESSIONID from the Set-Cookie header
                if let setCookieString = httpResponse.value(forHTTPHeaderField: "Set-Cookie") {
                    let pattern = "JSESSIONID=([^;]+)"
                    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                        let nsRange = NSRange(
                            setCookieString.startIndex ..< setCookieString.endIndex,
                            in: setCookieString
                        )
                        if let match = regex.firstMatch(
                            in: setCookieString,
                            options: [],
                            range: nsRange
                        ), let range = Range(match.range(at: 1), in: setCookieString) {
                            let newSessionId = String(setCookieString[range])
                            // Store it and return
                            DispatchQueue.main.async {
                                self.jsessionId = newSessionId
                            }
                            print("Logged in successfully. JSESSIONID:", newSessionId)
                            return newSessionId
                        } else {
                            print("Could not parse JSESSIONID from Set-Cookie header.")
                            return nil
                        }
                    } else {
                        print("Failed to build regex for JSESSIONID.")
                        return nil
                    }
                }

                // 8) No Set-Cookie header present. If status 2xx, reuse existing session
                if (200 ... 299).contains(httpResponse.statusCode) {
                    if let existing = self.jsessionId {
                        print("No new Set-Cookie header. Reusing old JSESSIONID:", existing)
                        return existing
                    } else {
                        print("Login succeeded but no Set-Cookie header, and no stored session.")
                        return nil
                    }
                }

                // 9) If we get here, login failed (status not 2xx, no Set-Cookie)
                print("Login failed. HTTP status code:", httpResponse.statusCode)
                return nil

            } catch {
                print("Network error during login:", error)
                return nil
            }
        }
    
//    func getTcSessionInfo(tcEndpointUrl: String) async -> [String: Any]? {
//        // 1. Make sure we have a JSESSIONID from a prior login
//        guard let session = self.jsessionId else {
//            print("No JSESSIONID found. Please login first.")
//            return nil
//        }
//        
//        guard let url = URL(string: "\(tcEndpointUrl)") else {
//            print("Invalid URL string: \(tcEndpointUrl)")
//            return nil
//        }
//        
//        
//        // 3. Prepare payload with only header (empty state & policy)
//        let payload: [String: Any] = [
//            "header": [
//                "state": [:],
//                "policy": [:]
//            ]
//        ]
//        
//        // 4. Serialize that minimal payload
//        let jsonData: Data
//        do {
//            jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
//        } catch {
//            print("Failed to serialize JSON payload for session info:", error)
//            return nil
//        }
//        
//        // 5. Build URLRequest with Cookie header
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        //    Attach the existing JSESSIONID as a Cookie
//        request.setValue("JSESSIONID=\(session)", forHTTPHeaderField: "Cookie")
//        request.httpBody = jsonData
//        
//        do {
//            // 6. Execute the request
//            let (data, response) = try await URLSession.shared.data(for: request)
//            guard let httpResponse = response as? HTTPURLResponse else {
//                print("No HTTPURLResponse when fetching session info.")
//                return nil
//            }
//            
//            // 7. If status is not 2xx, treat as error
//            guard (200...299).contains(httpResponse.statusCode) else {
//                print("Failed to fetch session info. HTTP status:", httpResponse.statusCode)
//                return nil
//            }
//            
//            // 8. Parse JSON into a dictionary
//            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                //print("Session info response:", jsonObject)
//                return jsonObject
//            } else {
//                print("Could not decode JSON for session info.")
//                return nil
//            }
//            
//        } catch {
//            print("Network or decoding error during session info request:", error)
//            return nil
//        }
//    }
    
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
    func getUserHomeFolder(tcEndpointUrl: String, userUid: String) async -> [String: Any]? {
        // 1. Make sure we have a JSESSIONID from a prior login
        guard let session = self.jsessionId else {
            print("Cannot call getUserHomeFolder: no JSESSIONID stored. Please login first.")
            return nil
        }
        
        // 2. Build URL from the exact endpoint string that was passed in
        guard let url = URL(string: tcEndpointUrl) else {
            print("Invalid URL string: \(tcEndpointUrl)")
            return nil
        }
        
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
                "attributes": ["home_folder"]
            ]
        ]
        
        // 4. Serialize payload to Data
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Failed to serialize JSON payload for getUserHomeFolder: \(error)")
            return nil
        }
        
        // 5. Build POST request and attach JSESSIONID in Cookie header
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("JSESSIONID=\(session)", forHTTPHeaderField: "Cookie")
        request.httpBody = jsonData
        
        do {
            // 6. Execute the request
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("getUserHomeFolder did not return an HTTPURLResponse.")
                return nil
            }
            
            // 7. Check for 2xx status code
            guard (200...299).contains(httpResponse.statusCode) else {
                print("getUserHomeFolder failed. HTTP status = \(httpResponse.statusCode).")
                return nil
            }
            
            // 8. Parse the raw JSON dictionary
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                //print("Received raw user home_folder JSON: \(jsonObject)")
                return jsonObject
            } else {
                print("Could not decode JSON from getUserHomeFolder.")
                return nil
            }
        } catch {
            print("Network or decoding error during getUserHomeFolder: \(error)")
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
}
