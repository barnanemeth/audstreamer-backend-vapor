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

    // MARK: Private properties

    private let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
    private lazy var videoDownloadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 2
        return queue
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
        
        downloadRequest.videoURLs.forEach { videoURL in
            let operation = VideoDownloadOperation(
                videoURL: videoURL,
                shouldSendNotification: downloadRequest.sendNotification ?? false,
                application: request.application,
                httpClient: httpClient
            )
            videoDownloadQueue.addOperation(operation)
        }

        return Response(status: .ok)
    }
}
