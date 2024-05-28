//
//  EnvironmentAuthenticator.swift
//
//
//  Created by Barna Nemeth on 16/01/2024.
//

import Foundation
import Vapor

struct EnvironmentAuthenticator {

    // MARK: Properties

    let allowedEnvironments: [Environment]

    // MARK: Init

    init(allowedEnvironments: [Environment]) {
        self.allowedEnvironments = allowedEnvironments
    }
}

// MARK: - AsyncAuthenticator

extension EnvironmentAuthenticator: AsyncAuthenticator {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        if !allowedEnvironments.contains(try Environment.detect()) {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}
