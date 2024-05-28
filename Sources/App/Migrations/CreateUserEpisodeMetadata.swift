//
//  CreateUserEpisodeMetadata.swift
//  
//
//  Created by Barna Nemeth on 22/01/2024.
//

import Fluent

struct CreateUserEpisodeMetadata: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_episode_metadata")
            .id()
            .field("episodeId", .string, .references("episodes", "id"), .required)
            .field("userId", .string, .required)
            .field("isFavorite", .bool)
            .field("lastPlayedDate", .datetime)
            .field("lastPosition", .int32)
            .field("numberOfPlays", .int32)
            .field("createdAt", .datetime, .required)
            .field("updatedAt", .datetime, .required)
            .create()

    }

    func revert(on database: Database) async throws {
        try await database.schema("user_episode_metadata").delete()
    }
}
