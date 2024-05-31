//
//  GetEpisodesParams.swift
//
//
//  Created by Barna Nemeth on 16/01/2024.
//

import Foundation
import Vapor

struct GetEpisodesParams: Decodable, Validatable {

    // MARK: CodingKeys

    private enum CodingKeys: String, CodingKey {
        case fromDate = "from_date"
    }

    // MARK: Properties

    let fromDate: Int?

    // MARK: Init

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fromDate = try container.decodeIfPresent(Int.self, forKey: .fromDate)
    }

    // MARK: Validatable

    static func validations(_ validations: inout Validations) {
        validations.add("from_date", as: Int.self, is: .range(0...), required: false)
    }
}
