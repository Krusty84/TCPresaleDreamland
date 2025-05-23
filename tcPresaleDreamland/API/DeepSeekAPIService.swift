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
        guard let url = URL(string: APIConfig.deepSeekChaCcompletions) else {
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
}
