//
//  DevicesController.swift
//  
//
//  Created by Barna Nemeth on 16/01/2024.
//

import Foundation
import Vapor
import Fluent

struct DevicesController {

    // MARK: Constants

    private enum Constant {
        static let indexPath: PathComponent = "devices"
        static let allowedEnvironmentsToDeviceList: [Environment] = [.development]
    }

    // MARK: Private properties
}

// MARK: - RouteCollection

extension DevicesController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        routes
            .grouped(Constant.indexPath)
            .grouped(APIKeyAuthenticator(), EnvironmentAuthenticator(allowedEnvironments: Constant.allowedEnvironmentsToDeviceList))
            .get(use: getDevices)

        routes
            .grouped(APIKeyAuthenticator(), BearerAuthenticator())
            .group(Constant.indexPath) { group in
                group.post(use: createDevice)
                group.delete(use: deleteDevice)
            }
    }
}

// MARK: - Handlers

extension DevicesController {
    private func getDevices(request: Request) async throws -> [Device] {
        try await Device.query(on: request.db).sort(\.$updatedAt).all()
    }

    private func createDevice(request: Request) async throws -> Response {
        try CreateDeviceRequest.validate(content: request)
        let deviceHeaderContent = try extractDeviceHeaderContent(from: request)
        let notificationToken = try request.content.decode(CreateDeviceRequest.self).notificationToken

        try await createOrUpdateDevice(
            database: request.db,
            userID: request.storage.get(UserIDStorageKey.self)!,
            deviceID: deviceHeaderContent.id,
            notificationToken: notificationToken
        )

        return Response(status: .ok)
    }

    private func deleteDevice(request: Request) async throws -> Response {
        let userID = request.storage.get(UserIDStorageKey.self)!
        let deviceHeaderContent = try extractDeviceHeaderContent(from: request)
        try await Device.query(on: request.db)
            .group(.and) { group in
                group
                    .filter(\.$userID, .equal, userID)
                    .filter(\.$deviceID, .equal, deviceHeaderContent.id)
            }
            .delete()

        return Response(status: .ok)
    }
}

// MARK: - Helpers

extension DevicesController {
    private func extractDeviceHeaderContent(from request: Request) throws -> DeviceHeaderContent {
        guard let deviceHeaderContent = DeviceHeaderContent(from: request.headers) else {
            throw Abort(.badRequest, reason: "Missing device info")
        }
        return deviceHeaderContent
    }

    private func createOrUpdateDevice(database: Database,
                                      userID: String,
                                      deviceID: String,
                                      notificationToken: String) async throws {
        let existingDevice = try await Device.query(on: database)
            .group(.and) { group in
                group
                    .filter(\.$userID, .equal, userID)
                    .filter(\.$deviceID, .equal, deviceID)
            }
            .first()
        if let existingDevice {
            existingDevice.notificationToken = notificationToken
            try await existingDevice.save(on: database)
        } else {
            let device = Device(userID: userID, deviceID: deviceID, notificationToken: notificationToken)
            try await device.save(on: database)
        }
    }
}
