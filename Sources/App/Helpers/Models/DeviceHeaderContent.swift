//
//  DeviceHeaderContent.swift
//
//
//  Created by Barna Nemeth on 16/01/2024.
//

import Foundation
import Vapor

struct DeviceHeaderContent {

    // MARK: Constants

    private enum Keys {
        static let idKey = "x-device-id"
        static let nameKey = "x-device-name"
        static let typeKey = "x-device-type"
    }

    // MARK: Properties

    let id: String
    let name: String?
    let type: String?

    // MARK: Init

    init?(from headers: HTTPHeaders) {
        guard let id = headers.first(name: Keys.idKey) else { return nil }
        self.id = id
        self.name = headers.first(name: Keys.nameKey)
        self.type = headers.first(name: Keys.typeKey)
    }
}
