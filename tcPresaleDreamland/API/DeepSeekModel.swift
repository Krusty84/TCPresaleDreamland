//
//  DeepSeek.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 22/05/2025.
//

import Foundation

// Define possible API errors for the service
enum APIError: Error {
    case invalidURL          // URL string was bad
    case invalidResponse     // Response was not HTTP
    case unauthorized        // API key rejected
    case httpError(statusCode: Int) // Other HTTP error
    case invalidJSON         // Failed to parse JSON
}
