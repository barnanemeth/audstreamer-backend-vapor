//
//  CreateEpisode.swift
//  
//
//  Created by Barna Nemeth on 14/01/2024.
//

import Fluent

struct CreateEpisode: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("episodes")
            .field("id", .string, .required, .sql(.primaryKey(autoIncrement: false)), .sql(.unique))
            .field("title", .sql(raw: "text"), .required)
            .field("description", .sql(raw: "text"))
            .field("link", .sql(raw: "text"))
            .field("audio", .sql(raw: "text"))
            .field("audioLengthSec", .int16, .required)
            .field("maybeAudioInvalid", .bool, .required, .sql(.default(0)))
            .field("image", .sql(raw: "text"))
            .field("thumbnail", .sql(raw: "text"))
            .field("publishDate", .sql(.bigint), .required)
            .field("createdAt", .datetime, .required)
            .field("updatedAt", .datetime, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("episodes").delete()
    }
}
