import Foundation
import NIOSSL
import APNS
import Fluent
import FluentMySQLDriver
import Vapor
import VaporAPNS
import APNSCore
import ShellOut

// configures your application
public func configure(_ app: Application) async throws {
    try initializeShell()
    configureDatabase(app)
    try addAndRunMigrations(app)
    try configureAPNS(app)
    try await fetchAppleJWKSKeys(app)
    try routes(app)
}

fileprivate func initializeShell() throws {
    let shouldUseVirtualEnvironment = Environment.get("USE_PYTHON_VIRTUAL_ENV") == String(true)

    try ShellUtil.checkNecessaryLaunchBinaries()
    if shouldUseVirtualEnvironment {
        try ShellUtil.createVirtualEnvironment()
        try ShellUtil.installDownloader()
    }
}

fileprivate func configureDatabase(_ app: Application) {
    guard let host = Environment.get("DATABASE_HOST"),
          let username = Environment.get("DATABASE_USERNAME"),
          let password = Environment.get("DATABASE_PASSWORD"),
          let database = Environment.get("DATABASE_NAME") else {
        fatalError("Cannot initialize database driver")
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
    app.migrations.add(CreateEpisode())
    app.migrations.add(CreateDevice())
    app.migrations.add(CreateUserEpisodeMetadata())

    try app.autoMigrate().wait()
}

fileprivate func configureAPNS(_ app: Application) throws {
    guard let teamID = Environment.get("APPLE_TEAM_ID"),
          let privateKeyID = Environment.get("APNS_PRIVATE_KEY_ID"),
          let privateKeyBase64 = Environment.get("APNS_PRIVATE_KEY_BASE64"),
          let privateKeyData = Data(base64Encoded: privateKeyBase64),
          let privateKeyString = String(data: privateKeyData, encoding: .utf8) else {
        fatalError("Cannot configure APNS")
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
    let uri = URI(string: "https://appleid.apple.com/auth/keys")
    guard let body = try? await app.client.get(uri).body,
            let data = body.getData(at: .zero, length: body.readableBytes),
            let keys = String(data: data, encoding: .utf8) else {
        fatalError("Cannot retreive Apple JWKS keys")
    }
    AppleJWKSKeysStorage.keys = keys
}
