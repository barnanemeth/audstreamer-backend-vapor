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

final class DownloadController {

    // MARK: Constants

    private enum Constant {
        static let indexPath: PathComponent = "download"
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

    private let jsonDecoder = JSONDecoder()
    private let fileManager = FileManager.default
    private let bundleID = Environment.get("BUNDLE_ID")
    private let ffmpegLocation = Environment.get("FFMPEG_LOCATION")
    private let s3Config = S3Config()
    private let queue = OperationQueue()

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

        queue.addOperation {
            print("success")
        }

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
                let resultJson = try ShellUtil.downloadVideo(url: url.absoluteString, with: arguments)
                let downloadResult = try decodeResult(from: resultJson)

                try await self.uploadFileAndDelete(
                    id: downloadResult.id,
                    directoryPath: application.directory.workingDirectory,
                    fileType: .mp3
                )

                let image = await uploadImageIfPossible(
                    downloadResult: downloadResult,
                    directoryPath: application.directory.workingDirectory
                )

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
}

