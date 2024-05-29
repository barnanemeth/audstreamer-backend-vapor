//
//  ShellUtil.swift
//
//
//  Created by Barna Nemeth on 28/05/2024.
//

import Foundation
import Vapor
import ShellOut

enum ShellUtilError: Error, LocalizedError {
    case missingLaunchBinary(String)
    case cannotCreateVirtualEnvironment(Error)

    var errorDescription: String? {
        switch self {
        case let .missingLaunchBinary(launchBinary):
            "Missing launch binary \(launchBinary)"
        case let .cannotCreateVirtualEnvironment(error):
            "Cannot create virtual environment: \(error.localizedDescription)"
        }
    }
}

enum ShellUtil {

    // MARK: Constants

    private enum Constant {
        static let defaultEnvironmentPath = "./_pyenv"
        static let necessaryLaunchBinaries = LaunchBinary.allCases
    }

    private enum LaunchBinary: CaseIterable {
        case python
        case ffmpeg

        var location: String {
            switch self {
            case .python: "python3"
            case .ffmpeg: Environment.get("FFMPEG_LOCATION") ?? "ffmpeg"
            }
        }
    }

    // MARK: Private properties

    private static var environmentActivationCommand: String {
        "source \(Constant.defaultEnvironmentPath)/bin/activate"
    }
}

// MARK: - Internal methods

extension ShellUtil {
    static func checkNecessaryLaunchBinaries() throws {
        for launchBinary in Constant.necessaryLaunchBinaries {
            let output = try shellOut(to: "whereis \(launchBinary.location)")

            // TODO: check
//            if output.components(separatedBy: " ").count < 2 {
//                throw ShellUtilError.missingLaunchBinary(launchBinary.location)
//            }
        }
    }

    static func createVirtualEnvironment() throws {
        do {
            try checkVirtualEnvironment()
        } catch {
            do {
                try shellOut(to: "\(LaunchBinary.python.location) -m venv \(Constant.defaultEnvironmentPath)")
                try checkVirtualEnvironment()
            } catch {
                try shellOut(to: "rm -rf \(Constant.defaultEnvironmentPath)")
                throw ShellUtilError.cannotCreateVirtualEnvironment(error)
            }
        }
    }

    static func installDownloader() throws {
        try shellOut(to: [
            environmentActivationCommand,
            "pip3 install youtube-dl git+https://github.com/barnanemeth/youtube-dl",
            "deactivate"
        ])
    }

    @discardableResult
    static func downloadVideo(url: String, with arguments: [String], useVirtualEnvironment: Bool) throws -> String {
        var commands = ["youtube-dl \(arguments.map { $0 }.joined(separator: " ")) \(url)"]
        if useVirtualEnvironment {
            commands.insert(environmentActivationCommand, at: .zero)
            commands.append("deactivate")
        }
        return try shellOut(to: commands)
    }
}

// MARK: - Helpers

extension ShellUtil {
    private static func checkVirtualEnvironment() throws {
        try shellOut(to: [
            environmentActivationCommand,
            "deactivate"
        ])
    }
}
