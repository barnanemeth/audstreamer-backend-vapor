//
//  BootstrapError.swift
//
//
//  Created by Barna Nemeth on 02/06/2024.
//

import Foundation

enum BootstrapError: Error {
    case missingDatabaseConfig
    case missingAPNSConfig
    case cannotRetreiveJWKSKeys
    case missingRedisURL
}
