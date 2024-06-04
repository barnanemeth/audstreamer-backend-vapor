//
//  Episode.swift
//
//
//  Created by Barna Nemeth on 14/01/2024.
//

import Foundation
import Vapor
import Fluent

final class Episode: Model, Content {

    // MARK: Static properties

    static let schema = "episodes"

    // MARK: Properties

    @ID(custom: .id, generatedBy: .user) var id: String?
    @Field(key: "title") var title: String
    @Field(key: "description") var description: String?
    @Field(key: "link") var link: String?
    @Field(key: "audio") var audio: String?
    @Field(key: "audioLengthSec") var audioLengthSec: Int
    @Field(key: "maybeAudioInvalid") var maybeAudioInvalid: Bool
    @Field(key: "image") var image: String?
    @Field(key: "thumbnail") var thumbnail: String?
    @Field(key: "publishDate") var publishDate: Int
    @Parent(key: "mediaSourceId") var mediaSource: MediaSource
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?
    @Timestamp(key: "updatedAt", on: .update) var updatedAt: Date?
}

// MARK: - Codable

extension Episode: Codable {
    private enum CodingKeys: String, CodingKey {
        case thumbnail
        case publishDate = "pub_date_ms"
        case id
        case title
        case image
        case link
        case description = "description"
        case audio
        case maybeAudioInvalid = "maybe_audio_invalid"
        case audioLengthSec = "audio_length_sec"
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init()

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String?.self, forKey: .description)
        link = try container.decode(String?.self, forKey: .link)
        audio = try container.decode(String?.self, forKey: .audio)
        audioLengthSec = (try? container.decode(Int?.self, forKey: .audioLengthSec)) ?? 0
        maybeAudioInvalid = try container.decode(Bool.self, forKey: .maybeAudioInvalid)
        image = try container.decode(String?.self, forKey: .image)
        thumbnail = try container.decode(String?.self, forKey: .thumbnail)
        publishDate = try container.decode(Int.self, forKey: .publishDate)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(link, forKey: .link)
        try container.encode(audio, forKey: .audio)
        try container.encode(audioLengthSec, forKey: .audioLengthSec)
        try container.encode(maybeAudioInvalid, forKey: .maybeAudioInvalid)
        try container.encode(image, forKey: .image)
        try container.encode(thumbnail, forKey: .thumbnail)
        try container.encode(publishDate, forKey: .publishDate)
    }
}
