//
//  VideoDownloadResult.swift
//
//
//  Created by Barna Nemeth on 29/05/2024.
//

import Foundation

struct VideoDownloadResult: Decodable {

    // MARK: Properties

    let id: String
    let title: String
    let description: String
    let duration: Int

    // MARK: Coding keys

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case duration
    }

    // MARK: Init

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.duration = try container.decode(Int.self, forKey: .duration)
    }
}
