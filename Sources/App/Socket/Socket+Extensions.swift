//
//  Socket+Extensions.swift
//
//
//  Created by Barna Nemeth on 16/01/2024.
//

import Foundation
import SocketIO

extension Socket {
    var userID: String {
        (userInfo[SocketDevice.userInfoKey] as? SocketDevice)?.userID ?? ""
    }
}
