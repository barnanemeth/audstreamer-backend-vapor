//
//  CreateDevice.swift
//  
//
//  Created by Barna Nemeth on 14/01/2024.
//

import Fluent

struct CreateDevice: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("devices")
            .id()
            .field("userId", .string, .required)
            .field("deviceId", .string, .required, .sql(.unique))
            .field("notificationToken", .string, .required, .sql(.unique))
            .field("createdAt", .datetime, .required)
            .field("updatedAt", .datetime, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("devices").delete()
    }
}
