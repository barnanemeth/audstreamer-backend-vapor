//
//  Application+Extensions.swift
//
//
//  Created by Barna Nemeth on 03/06/2024.
//

import Vapor

extension Application {
    var isRunningInQueueMode: Bool {
        environment.commandInput.arguments.contains("queues")
    }
}
