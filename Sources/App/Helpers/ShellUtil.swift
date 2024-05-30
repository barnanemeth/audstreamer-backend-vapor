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

    private static var useVirtualEnvironment = Environment.get("USE_PYTHON_VIRTUAL_ENV") == String(true)
    private static var environmentActivationCommand: String {
        "source \(Constant.defaultEnvironmentPath)/bin/activate"
    }

}

// MARK: - Internal methods

extension ShellUtil {
    static func checkNecessaryLaunchBinaries() throws {
        for launchBinary in Constant.necessaryLaunchBinaries {
            Logger.shellLogger.info("Checking launch binary \(launchBinary.location)")
            let output = try shellOut(to: "whereis \(launchBinary.location)")

            // TODO: check
//            if output.components(separatedBy: " ").count < 2 {
//                Logger.shellLogger.error("Launch binary not found: \(launchBinary.location)")
//                throw ShellUtilError.missingLaunchBinary(launchBinary.location)
//            }
        }
    }

    static func createVirtualEnvironmentIfNeeded() throws {
        guard useVirtualEnvironment else { return }
        do {
            try checkVirtualEnvironmentIfPossible()
        } catch {
            do {
                Logger.shellLogger.info("Creating virtual python environment")
                try shellOut(to: "\(LaunchBinary.python.location) -m venv \(Constant.defaultEnvironmentPath)")
                try checkVirtualEnvironmentIfPossible()
            } catch {
                Logger.shellLogger.error("Cannot reate virtual python environment")
                try shellOut(to: "rm -rf \(Constant.defaultEnvironmentPath)")
                throw ShellUtilError.cannotCreateVirtualEnvironment(error)
            }
        }
    }

    static func installDownloaderIfNeeded() throws {
        guard useVirtualEnvironment else { return }
        Logger.shellLogger.info("Installing downloader")
        try shellOut(to: [
            environmentActivationCommand,
            "pip3 install youtube-dl git+https://github.com/barnanemeth/youtube-dl",
            "deactivate"
        ])
    }

    @discardableResult
    static func downloadVideo(url: String, with arguments: [String]) throws -> String {
        var commands = ["youtube-dl \(arguments.map { $0 }.joined(separator: " ")) \(url)"]
        if useVirtualEnvironment {
            commands.insert(environmentActivationCommand, at: .zero)
            commands.append("deactivate")
        }
        Logger.shellLogger.info("Starting downlading video; URL: \(url); arguments: \(arguments)")
        return try shellOut(to: commands)
    }
}

// MARK: - Helpers

extension ShellUtil {
    private static func checkVirtualEnvironmentIfPossible() throws {
        guard useVirtualEnvironment else { return }
        Logger.shellLogger.info("Checking virtual python environment")
        try shellOut(to: [
            environmentActivationCommand,
            "deactivate"
        ])
    }
}
