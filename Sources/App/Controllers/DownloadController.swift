//
//  DownloadController.swift
//  
//
//  Created by Barna Nemeth on 29/05/2024.
//

import Foundation
import Vapor
import Fluent
import Queue

final class DownloadController {

    // MARK: Constants

    private enum Constant {
        static let indexPath: PathComponent = "download"
    }

}

// MARK: - RouteCollection

extension DownloadController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        routes
            .grouped(Constant.indexPath)
            .grouped(APIKeyAuthenticator(), UsernamePasswordAuthenticator())
            .post(use: download)
    }
}

// MARK: - Handlers

extension DownloadController {
    private func download(request: Request) async throws -> Response {
        try DownloadEpisodeRequest.validate(content: request)
        let downloadRequest = try request.content.decode(DownloadEpisodeRequest.self)
        for url in downloadRequest.videoURLs {
            try await request.queue.dispatch(VideoDownloadJob.self, url as VideoDownloadJob.Payload)
        }
        return Response(status: .accepted)
    }
}
