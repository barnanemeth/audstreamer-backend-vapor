//
//  SocketDevice.swift
//
//
//  Created by Barna Nemeth on 16/01/2024.
//

import Foundation

struct SocketDevice {

    static let userInfoKey = "socketDevice"

    // MARK: Properties

    let userID: String
    let deviceID: String
    let deviceName: String
    let deviceType: String
    let connectionTime = Date()

    var dicitonary: [String: Any] {
        [
            "id": deviceID,
            "name": deviceName,
            "type": deviceType,
            "connectionTime": Int(connectionTime.timeIntervalSince1970)
        ]
    }

    // MARK: Init

    init?(userID: String, deviceHeaderContent: DeviceHeaderContent) {
        guard let deviceName = deviceHeaderContent.name, let deviceType = deviceHeaderContent.type else { return nil }
        self.userID = userID
        self.deviceID = deviceHeaderContent.id
        self.deviceName = deviceName
        self.deviceType = deviceType
    }
}

// MARK: - Hashable

extension SocketDevice: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(deviceID)
    }
}
