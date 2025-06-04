//
//  DeepSeekAPIService.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 22/05/2025.
//

import Foundation

class DeepSeekAPIService: ObservableObject {
    static let shared = DeepSeekAPIService()
    @Published var apiKeyValid: Bool = false

    func verifyAPIKey(apiKey: String) async throws -> Bool {
        guard let url = URL(string: APIConfig.deepSeekChatCcompletions) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Minimal payload to validate the key without consuming tokens
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [] // Empty array to avoid token usage
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 400:
            // Special case: If the API returns 400 (Bad Request) due to empty messages,
            // but the key itself is valid, we can still consider it a success.
            return true
        case 401:
            throw APIError.unauthorized // Invalid API Key
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    func chatLLM(apiKey: String, prompt: String, temperature:Double, max_tokens:Int) async throws -> [String: Any] {
        print("1. Starting chatLLM")
        guard let url = URL(string: APIConfig.deepSeekChatCcompletions) else {
            print("2. Invalid URL")
            throw APIError.invalidURL
        }
        
        print("3. URL is valid: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": "You are a helpful and high experience system engineer"],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"],
            // Optional settings:
            "temperature": temperature,
            "max_tokens": max_tokens
        ]
        
        print("4. Request body created")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("5. Starting network request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("6. Network request completed")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("7. Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("8. Received HTTP response: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200...299:
            print("9. Success status code")
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("10. JSON parsed successfully")
                print("data: ",json)
                return json
            } else {
                print("11. Invalid JSON")
                throw APIError.invalidJSON
            }
        case 401:
            print("12. Unauthorized")
            throw APIError.unauthorized
        default:
            print("13. HTTP Error: \(httpResponse.statusCode)")
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}
