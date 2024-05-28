//
//  UserEpisodeMetadata.swift
//  
//
//  Created by Barna Nemeth on 22/01/2024.
//

import Foundation
import Vapor
import Fluent

final class UserEpisodeMetadata: Model, Content {
    
    // MARK: Static properties

    static let schema = "user_episode_metadata"

    // MARK: Properties

    @ID() var id: UUID?
    @Parent(key: "episodeId") var episode: Episode
    @Field(key: "userId") var userID: String
    @Field(key: "isFavorite") var isFavorite: Bool?
    @Field(key: "lastPlayedDate") var lastPlayedDate: Date?
    @Field(key: "lastPosition") var lastPosition: Int?
    @Field(key: "numberOfPlays") var numberOfPlays: Int?
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?
    @Timestamp(key: "updatedAt", on: .update) var updatedAt: Date?
}

// MARK: - Codable

extension UserEpisodeMetadata: Encodable {
    private enum CodingKeys: String, CodingKey {
        case episodeID = "episodeId"
        case isFavorite
        case lastPlayedDate
        case lastPosition
        case numberOfPlays

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(episode.id, forKey: .episodeID)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(lastPlayedDate, forKey: .lastPlayedDate)
        try container.encode(lastPosition, forKey: .lastPosition)
        try container.encode(numberOfPlays, forKey: .numberOfPlays)
    }
}
