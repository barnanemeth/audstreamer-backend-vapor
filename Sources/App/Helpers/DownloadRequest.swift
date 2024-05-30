//
//  DownloadRequest.swift
//
//
//  Created by Barna Nemeth on 29/05/2024.
//

import Foundation
import Vapor

struct DownloadRequest: Codable, Validatable {

    // MARK: Properties

    let videoURL: URL
    let sendNotification: Bool?

    // MARK: Validatable

    static func validations(_ validations: inout Validations) {
        validations.add("videoURL", as: URL.self, required: true)
        validations.add("sendNotification", as: Bool.self, required: false)
    }
}
