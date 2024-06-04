import Foundation
import NIOSSL
import APNS
import Fluent
import FluentMySQLDriver
import Vapor
import VaporAPNS
import APNSCore
import ShellOut
import QueuesRedisDriver

public func configure(_ app: Application) async throws {
    try initializeShell(app)
    try configureDatabase(app)
    try addAndRunMigrations(app)
    try configureAPNS(app)
    try await fetchAppleJWKSKeys(app)
    try setupQueue(app)
    try routes(app)
}

fileprivate func initializeShell(_ app: Application) throws {
    guard app.isRunningInQueueMode else { return }

    try ShellUtil.checkNecessaryLaunchBinaries()
    try ShellUtil.createVirtualEnvironmentIfNeeded()
    try ShellUtil.installDownloaderIfNeeded()
}

fileprivate func configureDatabase(_ app: Application) throws {
    guard let host = Environment.get("DATABASE_HOST"),
          let username = Environment.get("DATABASE_USERNAME"),
          let password = Environment.get("DATABASE_PASSWORD"),
          let database = Environment.get("DATABASE_NAME") else {
        throw BootstrapError.missingDatabaseConfig
    }

    let mysql = DatabaseConfigurationFactory.mysql(
        hostname: host,
        username: username,
        password: password,
        database: database,
        tlsConfiguration: .none
    )
    app.databases.use(mysql, as: .mysql)
}

fileprivate func addAndRunMigrations(_ app: Application) throws {
    guard !app.isRunningInQueueMode else { return }

    app.migrations.add(CreateEpisode())
    app.migrations.add(CreateDevice())
    app.migrations.add(CreateUserEpisodeMetadata())
    app.migrations.add(CreateMediaSource())
    app.migrations.add(AddEpisodeMediaSourceRelation())

    try app.autoMigrate().wait()
}

fileprivate func configureAPNS(_ app: Application) throws {
    guard let teamID = Environment.get("APPLE_TEAM_ID"),
          let privateKeyID = Environment.get("APNS_PRIVATE_KEY_ID"),
          let privateKeyBase64 = Environment.get("APNS_PRIVATE_KEY_BASE64"),
          let privateKeyData = Data(base64Encoded: privateKeyBase64),
          let privateKeyString = String(data: privateKeyData, encoding: .utf8) else {
        throw BootstrapError.missingAPNSConfig
    }

    let environment: APNSEnvironment
    switch app.environment {
    case .development: environment = .sandbox
    case .production: environment = .production
    default: environment = .sandbox
    }

    let apnsConfig = APNSClientConfiguration(
        authenticationMethod: .jwt(
            privateKey: try .loadFrom(string: privateKeyString),
            keyIdentifier: privateKeyID,
            teamIdentifier: teamID
        ),
        environment: environment
    )
    app.apns.containers.use(
        apnsConfig,
        eventLoopGroupProvider: .shared(app.eventLoopGroup),
        responseDecoder: JSONDecoder(),
        requestEncoder: JSONEncoder(),
        as: .default
    )
}

fileprivate func fetchAppleJWKSKeys(_ app: Application) async throws {
    guard !app.isRunningInQueueMode else { return }

    let uri = URI(string: "https://appleid.apple.com/auth/keys")
    guard let body = try? await app.client.get(uri).body,
            let data = body.getData(at: .zero, length: body.readableBytes),
            let keys = String(data: data, encoding: .utf8) else {
        throw BootstrapError.cannotRetreiveJWKSKeys
    }
    AppleJWKSKeysStorage.keys = keys
}

fileprivate func setupQueue(_ app: Application) throws {
    guard let redisURL = Environment.get("REDIS_URL") else { throw BootstrapError.missingRedisURL }

    try app.queues.use(.redis(url: redisURL))
    app.queues.add(VideoDownloadJob())
}
