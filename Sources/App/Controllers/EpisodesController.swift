//
//  EpisodesController.swift
//
//
//  Created by Barna Nemeth on 15/01/2024.
//

import Foundation
import Vapor
import Fluent
import SotoS3

struct EpisodesController {

    // MARK: Constants

    private enum Constant {
        static let indexPath: PathComponent = "episodes"
        static let fromDateQueryKey = "from_date"
        static let idPathParamName = "id"
    }
}

// MARK: - RouteCollection

extension EpisodesController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        routes
            .grouped(Constant.indexPath)
            .grouped(APIKeyAuthenticator())
            .get(use: getEpisodes)

        routes
            .grouped(Constant.indexPath, ":\(Constant.idPathParamName)")
            .grouped(APIKeyAuthenticator(), UsernamePasswordAuthenticator())
            .delete(use: delete)
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


    private func delete(request: Request) async throws -> Response {
        guard let id = request.parameters.get(Constant.idPathParamName) else {
            throw Abort(.badRequest, reason: "Missing id")
        }
        await deleteEpisode(id: id, database: request.db)
        return Response(status: .ok)
    }
}

// MARK: - Helpers

extension EpisodesController {
    private func deleteEpisode(id: String, database: Database) async {
        let episode = try? await Episode.query(on: database)
            .group(.and) { group in
                group
                    .filter(\.$id, .equal, id)
            }
            .all().first

        guard let episode else { return }

        let audio = episode.audio
        let image = episode.image

        try? await episode.delete(on: database)

        let s3Config = S3Config()
        let client = AWSClient(
            credentialProvider: CredentialProviderFactory.static(
                accessKeyId: s3Config.accessKeyID,
                secretAccessKey: s3Config.secretAccessKey
            ),
            httpClientProvider: .createNew
        )
        let s3 = S3(client: client, endpoint: s3Config.endpointURL)

        if let audio, let audioKey = URL(string: audio)?.lastPathComponent {
            _ = try? await s3.deleteObject(S3.DeleteObjectRequest(bucket: s3Config.bucket, key: audioKey))
        }
        if let image, let imageKey = URL(string: image)?.lastPathComponent {
            _ = try? await s3.deleteObject(S3.DeleteObjectRequest(bucket: s3Config.bucket, key: imageKey))
        }

        try? client.syncShutdown()
    }
}
