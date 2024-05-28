//
//  ListenNotesConfig.swift
//
//
//  Created by Barna Nemeth on 15/01/2024.
//

import Vapor

struct ListenNotesConfig {

    // MARK: Properties

    let baseURL: String
    let apiKey: String
    let podcastID: String
    let webhookSecret: String

    var uri: URI { URI(string: "\(baseURL)/\(podcastID)") }

    // MARK: Init

    init?() {
        guard let baseURL = Environment.get("LISTEN_NOTES_BASE_URL"),
              let apiKey = Environment.get("LISTEN_NOTES_API_KEY"),
              let podcastID = Environment.get("LISTEN_NOTES_PODCAST_ID"),
              let webhookSecret = Environment.get("LISTEN_NOTES_WEBHOOK_SECRET") else { return nil }
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.podcastID = podcastID
        self.webhookSecret = webhookSecret
    }
}
