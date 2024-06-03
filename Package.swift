// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "audstreamer-backend-vapor",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0"),
        .package(url: "https://github.com/barnanemeth/socket.io-vapor", from: "1.0.2"),
        .package(url: "https://github.com/vapor/apns", from: "4.0.0"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.13.1"),
        .package(url: "https://github.com/JohnSundell/ShellOut", from: "2.3.0"),
        .package(url: "https://github.com/soto-project/soto", from: "6.8.0"),
        .package(url: "https://github.com/vapor/queues-redis-driver", from: "1.1.1"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "SocketIO", package: "socket.io-vapor"),
                .product(name: "VaporAPNS", package: "apns"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "ShellOut", package: "ShellOut"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),

            // Workaround for https://github.com/apple/swift-package-manager/issues/6940
            .product(name: "Vapor", package: "vapor"),
            .product(name: "Fluent", package: "Fluent"),
            .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
        ])
    ]
)
