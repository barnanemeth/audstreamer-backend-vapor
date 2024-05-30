//
//  DownloadController.swift
//  
//
//  Created by Barna Nemeth on 29/05/2024.
//

import Foundation
import Vapor
import Fluent
import VaporAPNS
import APNSCore
import SotoS3
import NIOCore

final class DownloadController {

    // MARK: Constants

    private enum Constant {
        static let indexPath: PathComponent = "download"
    }

    private enum FileType {
        case audio
        case image

        var contentType: String {
            switch self {
            case .audio: "audio/mpeg"
            case .image: "image/webp"
            }
        }

        var fileExtension: String {
            switch self {
            case .audio: "mp3"
            case .image: "webp"
            }
        }
    }

    // MARK: Private properties

    private let jsonDecoder = JSONDecoder()
    private let fileManager = FileManager.default
    private let bundleID = Environment.get("BUNDLE_ID")
    private let ffmpegLocation = Environment.get("FFMPEG_LOCATION")
    private let s3Config = S3Config()

    private lazy var s3: S3 = {
        let client = AWSClient(
            credentialProvider: CredentialProviderFactory.static(
                accessKeyId: s3Config.accessKeyID,
                secretAccessKey: s3Config.secretAccessKey
            ),
            httpClientProvider: .createNew
        )
        return S3(client: client, endpoint: s3Config.endpointURL)
    }()
}

// MARK: - RouteCollection

extension DownloadController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        routes
            .grouped(Constant.indexPath)
            .grouped(APIKeyAuthenticator())
            .post(use: download)
    }
}

// MARK: - Handlers

extension DownloadController {
    private func download(request: Request) async throws -> Response {
        try DownloadRequest.validate(content: request)
        let downloadRequest = try request.content.decode(DownloadRequest.self)
        downloadVideo(
            url: downloadRequest.videoURL,
            shouldSendNotification: downloadRequest.sendNotification ?? false,
            application: request.application
        )
        return Response(status: .ok)
    }
}

// MARK: - Helpers

extension DownloadController {
    private func downloadVideo(url: URL, shouldSendNotification: Bool, application: Application) {
        Task {
            do {
                var downloadOptions: [VideoDownloadOption] = [
                    .quietMode,
                    .printJson,
                    .useVideoIDInFilename,
                    .writeThumbnail,
                    .extractAudio,
                    .audioFormat(.mp3),
                    .audioQuality(.best),
                    .preferFFMPEG
                ]
                if let ffmpegLocation {
                    downloadOptions.append(.ffmpegLocation(ffmpegLocation))
                }
                let arguments = downloadOptions.map { $0.argument }
                let json = try ShellUtil.downloadVideo(url: url.absoluteString, with: arguments)
                let downloadResult = try decodeResult(from: json)

                try await self.uploadFileAndDelete(
                    id: downloadResult.id,
                    directoryPath: application.directory.workingDirectory,
                    fileType: .audio
                )
                try await self.uploadFileAndDelete(
                    id: downloadResult.id,
                    directoryPath: application.directory.workingDirectory,
                    fileType: .image
                )

                let episode = Episode()
                episode.id = downloadResult.id
                episode.title = downloadResult.title
//                episode.description = downloadResult.description
                episode.audio = "\(s3Config.publicURL)/\(downloadResult.id).\(FileType.audio.fileExtension)"
                episode.audioLengthSec = downloadResult.duration
                episode.maybeAudioInvalid = false
                episode.image = "\(s3Config.publicURL)/\(downloadResult.id).\(FileType.image.fileExtension)"
                episode.thumbnail = "\(s3Config.publicURL)/\(downloadResult.id).\(FileType.image.fileExtension)"
                episode.publishDate = Int(Date.now.timeIntervalSince1970 * 1000)
                try await episode.save(on: application.db)

                // TODO: send notification

                application.logger.info("Video downloading is successfully finished (\(url))")
            } catch {
                application.logger.error("Error occurred during video downloading (\(url)): \(error)")
            }
        }
    }

    private func decodeResult(from resultJson: String) throws -> VideoDownloadResult {
        let data = resultJson.data(using: .utf8)!
        return try jsonDecoder.decode(VideoDownloadResult.self, from: data)
    }

    private func uploadFileAndDelete(id: String, directoryPath: String, fileType: FileType) async throws {
        let filename = "\(id).\(fileType.fileExtension)"
        guard let fileURL = URL(string: "file://\(directoryPath)/\(filename)") else {
            throw NSError(domain: "asd", code: 1)
        }
        _ = try await s3.putObject(
            S3.PutObjectRequest(
                body: AWSPayload.data(Data(contentsOf: fileURL)),
                bucket: s3Config.bucket,
                contentType: fileType.contentType,
                key: filename
            )
        )
        try fileManager.removeItem(at: fileURL)
    }
}

