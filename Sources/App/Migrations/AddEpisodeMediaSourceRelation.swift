//
//  AddEpisodeMediaSourceRelation.swift
//
//
//  Created by Barna Nemeth on 03/06/2024.
//

import Foundation
import Fluent
import SQLKit

struct AddEpisodeMediaSourceRelation: AsyncMigration {
    
    private enum `Error`: Swift.Error {
        case missingDefaultSourceID
    }

    func prepare(on database: Database) async throws {
        let mediaSource: MediaSource?
        if let first = try await database.query(MediaSource.self).first() {
            mediaSource = first
        } else {
            let defaultMediaSource = MediaSource()
            defaultMediaSource.name = "_default"
            try await defaultMediaSource.save(on: database)
            mediaSource = defaultMediaSource
        }

        guard let mediaSource else { throw Error.missingDefaultSourceID }

        try await database.schema("episodes")
            .field("mediaSourceId", .uuid, .references("media_sources", "id"))
            .update()

        try await (database as! SQLDatabase)
            .raw("UPDATE episodes SET mediaSourceId = \(bind: mediaSource.requireID())")
            .run()
    }

    func revert(on database: Database) async throws {
        try await database.schema("media_sources")
            .deleteField("mediaSourceId")
            .update()
    }
}
