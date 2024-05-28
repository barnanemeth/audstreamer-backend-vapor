//
//  AppleSignInJWTPayload.swift
//
//
//  Created by Barna Nemeth on 16/01/2024.
//

import Foundation
import JWTKit

struct AppleSignInJWTPayload: JWTPayload {

    // MARK: Properties

    let sub: SubjectClaim
    let aud: AudienceClaim
    let exp: ExpirationClaim

    // MARK: Public methods

    func verify(using signer: JWTSigner) throws {
        // TODO: future
//        try exp.verifyNotExpired()

    }
}
