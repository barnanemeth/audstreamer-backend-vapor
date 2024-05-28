//
//  EpisodesController.swift
//
//
//  Created by Barna Nemeth on 15/01/2024.
//

import Foundation
import Vapor

struct EpisodesController {

    // MARK: Constants

    private enum Constant {
        static let indexPath: PathComponent = "episodes"
        static let fromDateQueryKey = "from_date"
    }
}

// MARK: - RouteCollection

extension EpisodesController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        routes
            .grouped(Constant.indexPath)
            .grouped(APIKeyAuthenticator())
            .get(use: getEpisodes)
    }
}

// MARK: - Handlers

extension EpisodesController {
    private func getEpisodes(request: Request) async throws -> [Episode] {
        try GetEpisodesParams.validate(query: request)
        
        guard let fromDate = try request.query.decode(GetEpisodesParams.self).fromDate else {
            // All episodes
            return try await Episode.query(on: request.db).sort(\.$publishDate, .descending).all()
        }
        let episodes = try await Episode.query(on: request.db)
            .filter(\.$publishDate, .greaterThan, fromDate)
            .sort(\.$publishDate, .descending)
            .all()
        guard !episodes.isEmpty else { throw Abort(.noContent) }
        return episodes
    }
}
