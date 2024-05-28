//
//  EpisodesMetaController.swift
//
//
//  Created by Barna Nemeth on 23/01/2024.
//

import Foundation
import Vapor
import Fluent

struct EpisodesMetaController {

    // MARK: Constants

    private enum Constant {
        static let indexPath: PathComponent = "episodes-meta"
    }

    // MARK: Private properties
}

// MARK: - RouteCollection

extension EpisodesMetaController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        routes
            .grouped(APIKeyAuthenticator(), BearerAuthenticator())
            .group(Constant.indexPath) { group in
                group.get(use: getEpisodesMeta)
                group.post(use: updateEpisodesMeta)
            }
    }
}

// MARK: - Handlers

extension EpisodesMetaController {
    private func getEpisodesMeta(_ request: Request) async throws -> [UserEpisodeMetadata] {
        let userID = request.storage.get(UserIDStorageKey.self)!
        return try await UserEpisodeMetadata.query(on: request.db).filter(\.$userID, .equal, userID).all()
    }

    private func updateEpisodesMeta(_ request: Request) async throws -> Response {
        let userID = request.storage.get(UserIDStorageKey.self)!
        let items = try request.content.decode([EpisodesMetaUpdateItem].self)
        for item in items {
            try await createOrUpdateEpisodeMeta(with: item, userID: userID, database: request.db)
        }
        return Response(status: .ok)
    }
}

// MARK: - Helpers

extension EpisodesMetaController {
    private func createOrUpdateEpisodeMeta(with metaItem: EpisodesMetaUpdateItem,
                                           userID: String,
                                           database: Database) async throws {
        let query = UserEpisodeMetadata.query(on: database).group(.and) { group in
            group
                .filter(\.$userID, .equal, userID)
                .filter(\.$episode.$id, .equal, metaItem.episodeID)
        }

        let meta: UserEpisodeMetadata
        if let existingMeta = try await query.first() {
            meta = existingMeta
        } else {
            let newMeta = UserEpisodeMetadata()
            newMeta.$episode.id = metaItem.episodeID
            newMeta.userID = userID
            meta = newMeta
        }

        if let isFavorite = metaItem.isFavorite {
            meta.isFavorite = isFavorite
        }
        if let lastPlayedDate = metaItem.lastPlayedDate {
            meta.lastPlayedDate = lastPlayedDate
        }
        if let lastPosition = metaItem.lastPosition {
            meta.lastPosition = lastPosition
        }
        if let numberOfPlays = metaItem.numberOfPlays {
            meta.numberOfPlays = numberOfPlays
        }

        try await meta.save(on: database)
    }
}
