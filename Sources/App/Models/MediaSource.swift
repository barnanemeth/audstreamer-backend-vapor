//
//  MediaSource.swift
//
//
//  Created by Barna Nemeth on 03/06/2024.
//

import Foundation
import Vapor
import Fluent

final class MediaSource: Model {

    // MARK: Static properties

    static let schema = "media_sources"

    // MARK: Properties

    @ID() var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "description") var description: String?
    @Field(key: "image") var image: URL?
    @Children(for: \.$mediaSource) var episodes: [Episode]
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?
    @Timestamp(key: "updatedAt", on: .update) var updatedAt: Date?

    // MARK: Init

    init() { }

    init(name: String, description: String? = nil, image: URL? = nil) {
        self.name = name
        self.description = description
        self.image = image
    }
}
