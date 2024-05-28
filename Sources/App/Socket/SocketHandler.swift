//
//  SocketHandler.swift
//
//
//  Created by Barna Nemeth on 16/01/2024.
//

import Foundation
import Vapor
import SocketIO

final class SocketHandler {

    static let shared = SocketHandler()

    // MARK: Constants

    private enum Event {
        static let currentEpisode = "current_episode"
        static let playbackState = "playback_state"
        static let deviceListUpdate = "device_list_update"
        static let activeDevice = "active_device"
        static let playbackCommand = "playback_command"
    }

    // MARK: Private properties

    private lazy var server: SocketIOServer = {
        var config = SocketIOServer.Configuration.default
        config.logLevel = .info
        return SocketIOServer(configuration: config)
    }()

    // MARK: Init

    init() {
        setupMiddlewares()
        setupConnectionListener()
    }
}

// MARK: - RouteCollection

extension SocketHandler: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        try server.boot(routes: routes)
    }
}

// MARK: - Helpers

extension SocketHandler {
    private func setupMiddlewares() {
        server.use(SocketAuthMiddleware())
    }

    private func setupConnectionListener() {
        server.onConnection { [unowned self] server, socket in
            guard let socketDevice = socket.userInfo[SocketDevice.userInfoKey] as? SocketDevice else {
                return socket.disconnect()
            }

            Logger.socketLogger.info("Socket connected \(socketDevice.userID), \(socketDevice.deviceName)")

            socket.join(socketDevice.userID)

            let devices = self.getDeviceList(for: socketDevice.userID, in: server)
            server.to(socketDevice.userID).emit(event: Event.deviceListUpdate, data: devices.map { $0.dicitonary })
            server.to(socketDevice.userID).emit(
                event: Event.activeDevice,
                data: devices.min(by: { $0.connectionTime < $1.connectionTime })?.deviceID ?? ""
            )

            socket.onDisconnection { socket, _ in
                Logger.socketLogger.info("Socket disconnected \(socketDevice.userID), \(socketDevice.deviceName)")
                let devices = self.getDeviceList(for: socketDevice.userID, in: server)
                server.to(socketDevice.userID).emit(event: Event.deviceListUpdate, data: devices.map { $0.dicitonary })
            }

            socket.on(event: Event.currentEpisode) {
                Logger.socketLogger.info("Socket - \(Event.currentEpisode)")
                $0.to(socketDevice.userID).emit(event: Event.currentEpisode, data: $1)
            }
            socket.on(event: Event.playbackState) {
                Logger.socketLogger.info("Socket - \(Event.playbackState)")
                $0.to(socketDevice.userID).emit(event: Event.playbackState, data: $1)
            }
            socket.on(event: Event.activeDevice) {
                Logger.socketLogger.info("Socket - \(Event.activeDevice)")
                server.emit(event: Event.activeDevice, data: $1)
            }
            socket.on(event: Event.playbackCommand) {
                Logger.socketLogger.info("Socket - \(Event.playbackCommand)")
                $0.to(socketDevice.userID).emit(event: Event.playbackCommand, data: $1)
            }
        }
    }

    private func getDeviceList(for userID: String, in namespace: Namespace) -> [SocketDevice] {
        server.getSockets().compactMap { socket -> SocketDevice? in
            guard let socketDevice = socket.userInfo[SocketDevice.userInfoKey] as? SocketDevice,
                  socketDevice.userID == userID else { return nil }
            return socketDevice
        }
    }
}
