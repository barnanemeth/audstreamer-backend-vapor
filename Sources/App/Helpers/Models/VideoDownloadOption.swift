//
//  VideoDownloadOption.swift
//
//
//  Created by Barna Nemeth on 28/05/2024.
//

import Foundation

enum VideoDownloadOption {

    enum AudioFormat: String {
        case best
        case aac
        case flac
        case mp3
        case m4a
        case opus
        case vorbis
        case wav
    }

    struct AudioQuality: ExpressibleByIntegerLiteral {
        static let best: AudioQuality = 0
        static let worst: AudioQuality = 9

        let value: Int

        init(integerLiteral value: IntegerLiteralType) {
            self.value = value
        }
    }

    case quietMode
    case printJson
    case writeInfoJson
    case writeThumbnail
    case useVideoIDInFilename
    case extractAudio
    case audioFormat(AudioFormat)
    case audioQuality(AudioQuality)
    case preferFFMPEG
    case ffmpegLocation(String)
    case outputTemplate(String)
    case authentication(username: String, password: String)

    var argument: String {
        switch self {
        case .quietMode: "--quiet"
        case .printJson: "--print-json"
        case .writeInfoJson: "--write-info-json  "
        case .writeThumbnail: "--write-thumbnail"
        case .useVideoIDInFilename: "--id"
        case .extractAudio: "--extract-audio"
        case let .audioFormat(audioFormat): "--audio-format \(audioFormat.rawValue)"
        case let .audioQuality(audioQuality): "--audio-quality \(audioQuality.value)"
        case .preferFFMPEG: "--prefer-ffmpeg"
        case let .ffmpegLocation(path): "--ffmpeg-location \(path)"
        case let .outputTemplate(template): "-o \"\(template)\""
        case let .authentication(username, password): "--username \(username) --password \(password)"
        }
    }
}
