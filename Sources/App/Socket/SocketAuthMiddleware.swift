//
//  SocketAuthMiddleware.swift
//
//
//  Created by Barna Nemeth on 16/01/2024.
//

import Foundation
import Vapor
import SocketIO
import JWTKit

struct SocketAuthMiddleware { 

    // MARK: Private properties

    private let tokenVerificator = TokenVerificator()
}

// MARK: - NamespaceMiddleware

extension SocketAuthMiddleware: NamespaceMiddleware {
    func respond(to socket: Socket) async throws {
        guard let token = socket.client.handshake.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing auth token")
        }
        let userID = try tokenVerificator.verifyAndRetreiveUserID(token)
        guard let deviceHeaderContent = DeviceHeaderContent(from: socket.client.handshake.headers),
            let connectionMeta = SocketDevice(userID: userID, deviceHeaderContent: deviceHeaderContent) else {
            throw Abort(.badRequest, reason: "Missing device info")
        }
        socket.userInfo[SocketDevice.userInfoKey] = connectionMeta
    }
}
