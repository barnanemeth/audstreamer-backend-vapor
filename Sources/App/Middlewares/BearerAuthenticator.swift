//
//  BearerAuthenticator.swift
//
//
//  Created by Barna Nemeth on 16/01/2024.
//

import Foundation
import Vapor
import JWTKit

struct BearerAuthenticator {

    // MARK: Private properties

    private let tokenVerificator = TokenVerificator()
}

// MARK: - AsyncBearerAuthenticator

extension BearerAuthenticator: AsyncAuthenticator {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let token = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing auth token")
        }

        let userID = try tokenVerificator.verifyAndRetreiveUserID(token)
        request.storage.set(UserIDStorageKey.self, to: userID)
        return try await next.respond(to: request)
    }
}
