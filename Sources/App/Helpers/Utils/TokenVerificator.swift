//
//  TokenVerificator.swift
//
//
//  Created by Barna Nemeth on 16/01/2024.
//

import Foundation
import Vapor
import JWTKit

struct TokenVerificator {

    // MARK: Private properties

    private let bundleID: String

    // MARK: Init

    init() {
        guard let bundleID = Environment.get("BUNDLE_ID") else { fatalError("Cannot get Bundle ID") }
        self.bundleID = bundleID
    }
}

// MARK: - Public methods

extension TokenVerificator {
    func verifyAndRetreiveUserID(_ token: String) throws -> String {
        let signers = JWTSigners()
        try signers.use(jwksJSON: AppleJWKSKeysStorage.keys)

        do {
            let payload = try signers.verify(token, as: AppleSignInJWTPayload.self)
            return payload.sub.value
        } catch {
            throw Abort(.unauthorized, reason: "Invalid auth token")
        }
    }
}
