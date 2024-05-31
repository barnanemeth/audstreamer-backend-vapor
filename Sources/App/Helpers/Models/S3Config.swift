//
//  S3Config.swift
//
//
//  Created by Barna Nemeth on 15/01/2024.
//

import Vapor

struct S3Config {

    // MARK: Properties

    let accessKeyID: String
    let secretAccessKey: String
    let bucket: String
    let endpointURL: String
    let publicURL: String

    // MARK: Init

    init() {
        guard let accessKeyID = Environment.get("S3_ACCESS_KEY_ID"),
              let secretAccessKey = Environment.get("S3_SECRET_ACCESS_KEY"),
              let bucket = Environment.get("S3_BUCKET"),
              let endpointURL = Environment.get("S3_ENDPOINT_URL"),
              let publicURL = Environment.get("S3_PUBLIC_URL") else {
            fatalError("Cannot get S3 config")
        }
        self.accessKeyID = accessKeyID
        self.secretAccessKey = secretAccessKey
        self.bucket = bucket
        self.endpointURL = endpointURL
        self.publicURL = publicURL
    }
}
