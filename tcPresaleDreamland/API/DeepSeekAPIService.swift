//
//  DeepSeekAPIService.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 22/05/2025.
//

import Foundation

// Service to communicate with DeepSeek API
// Conforms to ObservableObject for SwiftUI bindings
class DeepSeekAPIService: ObservableObject {
    // Shared singleton instance for easy access
    static let shared = DeepSeekAPIService()
    
    // Published property to track if API key is valid
    @Published var apiKeyValid: Bool = false

    /// Verifies the given API key without using tokens
    /// - Parameter apiKey: DeepSeek API key string
    /// - Returns: true if the key is valid, false otherwise
    func verifyAPIKey(apiKey: String) async throws -> Bool {
        // Build URL from endpoint string
        guard let url = URL(string: APIConfig.deepSeekChatCcompletions) else {
            // Throw if URL is invalid
            throw APIError.invalidURL
        }
        
        // Create POST request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Add authorization header with Bearer token
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        // Indicate JSON content
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Minimal JSON body: empty messages to avoid token use
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [] // No messages means no tokens consumed
        ]
        // Serialize the body to JSON data
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Send request and await response
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // Ensure we got an HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle status codes
        switch httpResponse.statusCode {
        case 400:
            // Bad Request is expected for empty messages; key is valid
            return true
        case 401:
            // Unauthorized: API key is invalid
            throw APIError.unauthorized
        default:
            // Other codes treated as HTTP errors
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    /// Sends a chat prompt to DeepSeek and returns JSON response
    /// - Parameters:
    ///   - apiKey: DeepSeek API key string
    ///   - prompt: User's message to send
    ///   - temperature: Sampling temperature for creativity
    ///   - max_tokens: Maximum tokens to generate
    /// - Returns: Parsed JSON object from API
    func chatLLM(apiKey: String, prompt: String, temperature: Double, max_tokens: Int) async throws -> [String: Any] {
        print("1. Starting chatLLM")
        
        // Build URL for chat completions
        guard let url = URL(string: APIConfig.deepSeekChatCcompletions) else {
            print("2. Invalid URL")
            throw APIError.invalidURL
        }
        print("3. URL is valid: \(url)")
        
        // Create POST request with headers
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build messages payload
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": "You are a helpful and high experience system engineer"],
                ["role": "user", "content": prompt]
            ],
            // Ask for JSON object in response
            "response_format": ["type": "json_object"],
            // Optional settings for creativity and length
            "temperature": temperature,
            "max_tokens": max_tokens
        ]
        print("4. Request body created")
        // Serialize body to JSON
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("5. Starting network request...")
        // Send request and capture data and response
        let (data, response) = try await URLSession.shared.data(for: request)
        print("6. Network request completed")
        
        // Check response type
        guard let httpResponse = response as? HTTPURLResponse else {
            print("7. Invalid response type")
            throw APIError.invalidResponse
        }
        print("8. Received HTTP response: \(httpResponse.statusCode)")
        
        // Handle success and error codes
        switch httpResponse.statusCode {
        case 200...299:
            print("9. Success status code")
            // Try to parse JSON
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("10. JSON parsed successfully")
                print("data: ", json)
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
