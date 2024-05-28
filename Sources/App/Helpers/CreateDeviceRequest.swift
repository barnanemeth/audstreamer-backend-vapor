//
//  CreateDeviceRequest.swift
//
//
//  Created by Barna Nemeth on 16/01/2024.
//

import Foundation
import Vapor

struct CreateDeviceRequest: Codable, Validatable {

    // MARK: Properties

    let notificationToken: String

    // MARK: Validatable

    static func validations(_ validations: inout Validations) {
        validations.add("notificationToken", as: String.self, required: true)
    }
}
