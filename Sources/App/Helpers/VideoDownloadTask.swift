//
//  VideoDownloadTask.swift
//
//
//  Created by Barna Nemeth on 31/05/2024.
//

import Foundation
import Vapor
import VaporAPNS
import APNSCore
import SotoS3

enum VideoDownloadError: Error {
    case invalidURL
    case videoAlreadyExists
}

struct VideoDownloadTask {

    // MARK: Constants

    private enum Constant {
        static let baseDownloadOptions: [VideoDownloadOption] = [
            .quietMode,
            .printJson,
            .useVideoIDInFilename,
            .writeThumbnail,
            .extractAudio,
            .audioFormat(.mp3),
            .audioQuality(.best),
            .preferFFMPEG
        ]
        static let newEpisodeLoc = "newEpisode"
    }

    private enum FileType {
        case mp3
        case image(String)

        var contentType: String {
            switch self {
            case .mp3: "audio/mpeg"
            case .image: "image/\(fileExtension)"
            }
        }

        var fileExtension: String {
            switch self {
            case .mp3: "mp3"
            case let .image(fileExtension): fileExtension
            }
        }
    }

    // MARK: Private properties

    private let videoURL: URL
    private let shouldSendNotification: Bool
    private let application: Application
    private let httpClient: HTTPClient

    private var task: Task<Void, Error>?
    private let jsonDecoder = JSONDecoder()
    private let fileManager = FileManager.default
    private let bundleID = Environment.get("BUNDLE_ID")
    private let ffmpegLocation = Environment.get("FFMPEG_LOCATION")
    private let s3Config = S3Config()
    private let client: AWSClient
    private let s3: S3

    // MARK: Init

    init(videoURL: URL, shouldSendNotification: Bool, application: Application, httpClient: HTTPClient) {
        self.videoURL = videoURL
        self.shouldSendNotification = shouldSendNotification
        self.application = application
        self.httpClient = httpClient

        client = AWSClient(
            credentialProvider: CredentialProviderFactory.static(
                accessKeyId: s3Config.accessKeyID,
                secretAccessKey: s3Config.secretAccessKey
            ),
            httpClientProvider: .shared(httpClient)
        )
        s3 = S3(client: client, endpoint: s3Config.endpointURL)
    }

    // MARK: Internal methods

    func run() async throws {
        defer { try? client.syncShutdown() }

        do {
            try await checkExistingVideo()

            let downloadResult = try downloadVideo()

            try await uploadFileAndDelete(
                id: downloadResult.id,
                directoryPath: application.directory.workingDirectory,
                fileType: .mp3
            )

            let image = await uploadImageIfPossible(
                downloadResult: downloadResult,
                directoryPath: application.directory.workingDirectory
            )

            let episode = try await saveEpisode(downloadResult: downloadResult, image: image)

            try? await sendNotificationsIfNeeded(for: episode)

            application.logger.info("Video downloading is successfully finished (\(videoURL))")
        } catch {
            application.logger.error("Error occurred during video downloading (\(videoURL)): \(error)")
            throw error
        }
    }
}

// MARK: - Helpers

extension VideoDownloadTask {
    private func checkExistingVideo() async throws {
        guard let components = URLComponents(url: videoURL, resolvingAgainstBaseURL: false),
              let id = components.queryItems?.first(where: { $0.name == "v" })?.value else { return }
        if (try? await Episode.find(id, on: application.db)) != nil {
            throw VideoDownloadError.videoAlreadyExists
        }
    }

    private func downloadVideo() throws -> VideoDownloadResult {
        var downloadOptions = Constant.baseDownloadOptions
        if let ffmpegLocation {
            downloadOptions.append(.ffmpegLocation(ffmpegLocation))
        }
        let arguments = downloadOptions.map { $0.argument }
        let resultJson = try ShellUtil.downloadVideo(url: videoURL.absoluteString, with: arguments)
        return try decodeResult(from: resultJson)
    }

    private func decodeResult(from resultJson: String) throws -> VideoDownloadResult {
        let data = resultJson.data(using: .utf8)!
        return try jsonDecoder.decode(VideoDownloadResult.self, from: data)
    }

    private func uploadFileAndDelete(id: String, directoryPath: String, fileType: FileType) async throws {
        let filename = "\(id).\(fileType.fileExtension)"
        guard let fileURL = URL(string: "file://\(directoryPath)/\(filename)") else {
            throw VideoDownloadError.invalidURL
        }
        defer { try? fileManager.removeItem(at: fileURL) }
        _ = try await s3.putObject(
            S3.PutObjectRequest(
                body: AWSPayload.data(Data(contentsOf: fileURL)),
                bucket: s3Config.bucket,
                contentType: fileType.contentType,
                key: filename
            )
        )
    }

    private func uploadImageIfPossible(downloadResult: VideoDownloadResult, directoryPath: String) async -> String? {
        guard let thumbnailExtension = downloadResult.thumbnail?.lastPathComponent.components(separatedBy: ".").last else {
            return nil
        }
        do {
            try await self.uploadFileAndDelete(
                id: downloadResult.id,
                directoryPath: directoryPath,
                fileType: .image(thumbnailExtension)
            )
            return "\(s3Config.publicURL)/\(downloadResult.id).\(thumbnailExtension)"
        } catch {
            return nil
        }
    }

    private func saveEpisode(downloadResult: VideoDownloadResult, image: String?) async throws -> Episode {
        let episode = Episode()
        episode.id = downloadResult.id
        episode.title = downloadResult.title
        episode.description = ""
        episode.audio = "\(s3Config.publicURL)/\(downloadResult.id).\(FileType.mp3.fileExtension)"
        episode.audioLengthSec = downloadResult.duration
        episode.maybeAudioInvalid = false
        episode.image = image
        episode.thumbnail = image
        episode.publishDate = Int(Date.now.timeIntervalSince1970 * 1000)
        try await episode.save(on: application.db)
        return episode
    }

    private func sendNotificationsIfNeeded(for episode: Episode) async throws {
        guard shouldSendNotification else { return }

        let notificationTokens = try await Device.query(on: application.db).all(\.$notificationToken)

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
            _ = try? await application.apns.client.sendAlertNotification(notification, deviceToken: token)
        }
    }
}
