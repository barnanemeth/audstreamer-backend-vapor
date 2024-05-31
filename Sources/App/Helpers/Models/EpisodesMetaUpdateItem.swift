//
//  EpisodesMetaUpdateItem.swift
//
//
//  Created by Barna Nemeth on 23/01/2024.
//

import Foundation
import Vapor

struct EpisodesMetaUpdateItem: Validatable {

    // MARK: Properties

    let episodeID: String
    let isFavorite: Bool?
    let lastPlayedDate: Date?
    let lastPosition: Int?
    let numberOfPlays: Int?


    // MARK: Validatable

    static func validations(_ validations: inout Validations) {
        validations.add(CodingKeys.episodeID.basicCodingKey, as: String.self, required: true)
        validations.add(CodingKeys.isFavorite.basicCodingKey, as: Bool.self, required: false)
        validations.add(CodingKeys.lastPlayedDate.basicCodingKey, as: Date.self, required: false)
        validations.add(CodingKeys.lastPosition.basicCodingKey, as: Int.self, required: false)
        validations.add(CodingKeys.numberOfPlays.basicCodingKey, as: Int.self, required: false)
    }
}

// MARK: - Decodable

extension EpisodesMetaUpdateItem: Decodable {
    private enum CodingKeys: String, CodingKey {
        case episodeID = "episodeId"
        case isFavorite
        case lastPlayedDate
        case lastPosition
        case numberOfPlays

        var basicCodingKey: BasicCodingKey { .key(rawValue) }
    }
}

// MARK: - Array

extension Array where Element == EpisodesMetaUpdateItem {

}
