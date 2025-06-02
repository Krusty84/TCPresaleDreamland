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
    
    // This will hold the JSESSIONID string after a successful login
    @Published var jsessionId: String? = nil
    
    private init() {}
    
    func tcLogin(tcEndpointUrl: String, userName: String, userPassword: String) async -> String? {
        guard let url = URL(string: "\(tcEndpointUrl)") else {
            print("Invalid URL string: \(tcEndpointUrl)")
            return nil
        }
        
        // 2. Prepare JSON payload exactly as Teamcenter expects
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
        
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Failed to serialize JSON payload:", error)
            return nil
        }
        
        // 3. Build URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            // 4. Perform the network call
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("No HTTP response (not an HTTPURLResponse).")
                return nil
            }
            
            // 5. Optional: check if the JSON body itself contains a "code" field != 0
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let code = jsonObject["code"] as? Int, code != 0 {
                print("Login failed (Teamcenter returned code \(code)).")
                return nil
            }
            
            // 6. If there *is* a Set-Cookie header, parse out JSESSIONID
            if let setCookieString = httpResponse.value(forHTTPHeaderField: "Set-Cookie") {
                let pattern = "JSESSIONID=([^;]+)"
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    let nsRange = NSRange(setCookieString.startIndex..<setCookieString.endIndex,
                                          in: setCookieString)
                    if let match = regex.firstMatch(in: setCookieString, options: [], range: nsRange),
                       let range = Range(match.range(at: 1), in: setCookieString) {
                        let newSessionId = String(setCookieString[range])
                        // Store it in your published property if you have one:
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
            
            // 7. No Set-Cookie header present. If status code is 200–299, assume old session still works
            if (200...299).contains(httpResponse.statusCode) {
                if let existing = self.jsessionId {
                    print("No new Set-Cookie header. Reusing old JSESSIONID:", existing)
                    return existing
                } else {
                    print("Successful status but no existing session stored.")
                    return nil
                }
            }
            
            // 8. If we reach here, status is not in 200–299 and no Set-Cookie → error
            print("Login failed. HTTP status code:", httpResponse.statusCode)
            return nil
            
        } catch {
            print("Network or decoding error during login:", error)
            return nil
        }
    }
    
    func getTcSessionInfo(tcEndpointUrl: String) async -> [String: Any]? {
           // 1. Make sure we have a JSESSIONID from a prior login
           guard let session = self.jsessionId else {
               print("No JSESSIONID found. Please login first.")
               return nil
           }
           
           guard let url = URL(string: "\(tcEndpointUrl)") else {
               print("Invalid URL string: \(tcEndpointUrl)")
               return nil
           }
        
        
           // 3. Prepare payload with only header (empty state & policy)
           let payload: [String: Any] = [
               "header": [
                   "state": [:],
                   "policy": [:]
               ]
           ]
           
           // 4. Serialize that minimal payload
           let jsonData: Data
           do {
               jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
           } catch {
               print("Failed to serialize JSON payload for session info:", error)
               return nil
           }
           
           // 5. Build URLRequest with Cookie header
           var request = URLRequest(url: url)
           request.httpMethod = "POST"
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           
           //    Attach the existing JSESSIONID as a Cookie
           request.setValue("JSESSIONID=\(session)", forHTTPHeaderField: "Cookie")
           request.httpBody = jsonData
           
           do {
               // 6. Execute the request
               let (data, response) = try await URLSession.shared.data(for: request)
               guard let httpResponse = response as? HTTPURLResponse else {
                   print("No HTTPURLResponse when fetching session info.")
                   return nil
               }
               
               // 7. If status is not 2xx, treat as error
               guard (200...299).contains(httpResponse.statusCode) else {
                   print("Failed to fetch session info. HTTP status:", httpResponse.statusCode)
                   return nil
               }
               
               // 8. Parse JSON into a dictionary
               if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                   //print("Session info response:", jsonObject)
                   return jsonObject
               } else {
                   print("Could not decode JSON for session info.")
                   return nil
               }
               
           } catch {
               print("Network or decoding error during session info request:", error)
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

}
