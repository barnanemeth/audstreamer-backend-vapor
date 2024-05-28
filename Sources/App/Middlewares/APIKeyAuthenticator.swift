//
//  APIKeyAuthenticator.swift
//
//
//  Created by Barna Nemeth on 15/01/2024.
//

import Foundation
import Vapor

struct APIKeyAuthenticator {

    // MARK: Constants

    private enum Constant {
        static let apiKeyHeaderFieldName = "x-api-key"
    }

    // MARK: Private properties

    private let apiKey: String

    // MARK: Init

    init() {
        guard let apiKey = Environment.get("API_KEY") else { fatalError("API Key not found in environment") }
        self.apiKey = apiKey
    }
}

// MARK: - AsyncAuthenticator

extension APIKeyAuthenticator: AsyncAuthenticator {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let requestAPIKey = request.headers.first(name: Constant.apiKeyHeaderFieldName) else {
            throw Abort(.unauthorized, reason: "Missing API Key")
        }
        if requestAPIKey != apiKey {
            throw Abort(.unauthorized, reason: "Bad API Key")
        }
        return try await next.respond(to: request)
    }
}
