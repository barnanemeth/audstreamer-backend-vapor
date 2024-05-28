//
//  RefetchController.swift
//
//
//  Created by Barna Nemeth on 15/01/2024.
//

import Foundation
import Vapor
import Fluent
import VaporAPNS
import APNSCore

struct RefetchController {

    // MARK: Constants

    private enum Constant {
        static let indexPath: PathComponent = "refetch"
        static let webhookPath: PathComponent = "refetch-webhook"
        static let listenNotesApiKeyHeaderKey = "X-ListenAPI-Key"
        static let listeNotesWebhookSecretHeaderKey = "listenapi-webhook-secret"
        static let newEpisodeLoc = "newEpisode"
    }

    // MARK: Private properties

    private let isForcedNotificationSendingEnabled = Environment.get("FORCED_NOTIFICATION_SENDING") == String(true)
    private let bundleID = Environment.get("BUNDLE_ID")
    private let listenNotesConfig = ListenNotesConfig()
}

// MARK: - RouteCollection

extension RefetchController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        routes
            .grouped(Constant.indexPath)
            .grouped(APIKeyAuthenticator())
            .get(use: refetch)

        routes
            .grouped(Constant.webhookPath)
            .post(use: refetchWebhook)
    }
}

// MARK: - Handlers

extension RefetchController {
    private func refetch(request: Request) async throws -> Response {
        try await performRefetch(request: request)
        return Response(status: .ok)
    }

    private func refetchWebhook(request: Request) async throws -> Response {
        try validateListenNotesWebhookSecret(for: request)
        let body = try? request.content.decode([String: [String: String]].self)
        guard body?["podcast"]?["id"] == listenNotesConfig?.podcastID else { return Response(status: .ok) }
        try await performRefetch(request: request)
        return Response(status: .ok)
    }
}

// MARK: - Helpers

extension RefetchController {
    private func performRefetch(request: Request) async throws {
        let remoteEpisodes = try await fetchRemoteEpisodes(client: request.client)
        let localEpisodes = try await Episode.query(on: request.db).sort(\.$publishDate, .descending).all()

        let newEpisodes = remoteEpisodes.filter { remoteEpisode in
            !localEpisodes.contains(where: { $0.id == remoteEpisode.id })
        }
        
        // Save new episodes
        for episode in newEpisodes {
            try await episode.save(on: request.db)
        }

        if let newEpisode = newEpisodes.first {
            try await sendNotifications(for: newEpisode, apns: request.apns.client, database: request.db)
        } else if let remoteEpisode = remoteEpisodes.first, isForcedNotificationSendingEnabled {
            try await sendNotifications(for: remoteEpisode, apns: request.apns.client, database: request.db)
        }
    }

    private func fetchRemoteEpisodes(client: Client) async throws -> [Episode] {
        guard let listenNotesConfig else { throw Abort(.preconditionFailed) }
        let headers = HTTPHeaders([(Constant.listenNotesApiKeyHeaderKey, listenNotesConfig.apiKey)])
        let response = try await client.get(listenNotesConfig.uri, headers: headers)
        return try response.content.decode(ListenNotesEpisodesResponse.self).episodes
    }

    private func validateListenNotesWebhookSecret(for request: Request) throws {
        guard let listenNotesWebhookSecret = listenNotesConfig?.webhookSecret, 
              let requestSecret = request.headers.first(name: Constant.listeNotesWebhookSecretHeaderKey) else {
            throw Abort(.unauthorized)
        }
        if listenNotesWebhookSecret != requestSecret {
            throw Abort(.unauthorized)
        }
    }

    private func sendNotifications(for episode: Episode, apns: APNSGenericClient, database: Database) async throws {
        let notificationTokens = try await Device.query(on: database).all(\.$notificationToken)

        let alert = APNSAlertNotificationContent(title: .raw(Constant.newEpisodeLoc), body: .raw(episode.title))
        let payload = NotificationPayload(episodeID: episode.id!, imageURL: episode.image)
        let notification = APNSAlertNotification(
            alert: alert,
            expiration: .none,
            priority: .immediately,
            topic: bundleID ?? "",
            payload: payload, 
            mutableContent: 1
        )
        
        // TODO: send multiple notifications
        for token in notificationTokens {
            _ = try? await apns.sendAlertNotification(notification, deviceToken: token)
        }
    }
}
