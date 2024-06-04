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
    
    private enum Constant {
        static let episodesTableName = "episodes"
        static let mediaSourcesTableName = "media_sources"
        static let mediaSourceIdColumnName = "mediaSourceId"
        static let defaultMediaSourceName = "_default"
        static let foreignKeyName = "fk_media_sources_id"
    }

    private enum `Error`: Swift.Error {
        case missingDefaultSourceID
        case notSQL
    }

    func prepare(on database: Database) async throws {
        let mediaSource: MediaSource?
        if let first = try await database.query(MediaSource.self).first() {
            mediaSource = first
        } else {
            let defaultMediaSource = MediaSource()
            defaultMediaSource.name = Constant.defaultMediaSourceName
            try await defaultMediaSource.save(on: database)
            mediaSource = defaultMediaSource
        }

        guard let mediaSource else { throw Error.missingDefaultSourceID }
        guard let sqlDatabase = database as? SQLDatabase else { throw Error.notSQL }

        try await database.schema(Constant.episodesTableName)
            .field(FieldKey(stringLiteral: Constant.mediaSourceIdColumnName), .uuid)
            .update()

        try await sqlDatabase
            .raw("UPDATE \(raw: Constant.episodesTableName) SET \(raw: Constant.mediaSourceIdColumnName) = \(bind: mediaSource.requireID())")
            .run()

        try await sqlDatabase
            .raw("ALTER TABLE `\(raw: Constant.episodesTableName)` CHANGE `\(raw: Constant.mediaSourceIdColumnName)` `\(raw: Constant.mediaSourceIdColumnName)` varbinary(16) NOT NULL")
            .run()

        try await database.schema(Constant.episodesTableName)
            .foreignKey(
                FieldKey(stringLiteral: Constant.mediaSourceIdColumnName),
                references: Constant.mediaSourcesTableName,
                "id",
                name: Constant.foreignKeyName
            )
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Constant.episodesTableName)
            .deleteForeignKey(name: Constant.foreignKeyName)
            .update()

        try await database.schema(Constant.episodesTableName)
            .deleteField(FieldKey(stringLiteral: Constant.mediaSourceIdColumnName))
            .update()

    }
}
