//
//  Device.swift
//
//
//  Created by Barna Nemeth on 14/01/2024.
//

import Foundation
import Fluent
import Vapor

final class Device: Model, Content {
    
    // MARK: Static properties

    static let schema = "devices"

    // MARK: Properties

    @ID() var id: UUID?
    @Field(key: "userId") var userID: String
    @Field(key: "deviceId") var deviceID: String
    @Field(key: "notificationToken") var notificationToken: String
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?
    @Timestamp(key: "updatedAt", on: .update) var updatedAt: Date?

    // MARK: Init

    init() { }

    init(userID: String, deviceID: String, notificationToken: String) {
        self.userID = userID
        self.deviceID = deviceID
        self.notificationToken = notificationToken
    }
}
