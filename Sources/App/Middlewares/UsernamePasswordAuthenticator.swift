//
//  UsernamePasswordAuthenticator.swift
//
//
//  Created by Barna Nemeth on 31/05/2024.
//

import Foundation
import Vapor

struct UsernamePasswordAuthenticator {

    // MARK: Private properties

    private let username: String
    private let password: String

    // MARK: Init

    init() {
        guard let username = Environment.get("BASIC_AUTH_USERNAME"),
              let password = Environment.get("BASIC_AUTH_PASSWORD") else {
            fatalError("Cannot get base auth values")
        }
        self.username = username
        self.password = password
    }
}

// MARK: 

extension UsernamePasswordAuthenticator: AsyncAuthenticator {
    func respond(to request: Vapor.Request, chainingTo next: any Vapor.AsyncResponder) async throws -> Vapor.Response {
        guard let basicAuth = request.headers.basicAuthorization else {
            throw Abort(.unauthorized, reason: "Missing auth")
        }
        if basicAuth.username != username || basicAuth.password != password {
            throw Abort(.unauthorized, reason: "Bad username or password")
        }
        return try await next.respond(to: request)
    }
}
