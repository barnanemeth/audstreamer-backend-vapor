//
//  CreateMediaSource.swift
//  
//
//  Created by Barna Nemeth on 03/06/2024.
//

import Fluent

struct CreateMediaSource: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("media_sources")
            .id()
            .field("name", .string, .required)
            .field("description", .sql(raw: "text"))
            .field("image", .sql(raw: "text"))
            .field("createdAt", .datetime, .required)
            .field("updatedAt", .datetime, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("media_sources").delete()
    }
}
