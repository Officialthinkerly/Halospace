//
//  HaloLogger.swift
//  HaloSpace V3
//

import Foundation
import OSLog

enum HaloLog {
    private static let subsystem = "com.halospace.v3"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let spatial = Logger(subsystem: subsystem, category: "spatial")
    static let handTracking = Logger(subsystem: subsystem, category: "hand-tracking")
    static let windows = Logger(subsystem: subsystem, category: "windows")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let web = Logger(subsystem: subsystem, category: "web")

    #if DEBUG
    static var verboseEnabled = true
    #else
    static var verboseEnabled = false
    #endif

    static func debug(_ message: String, logger: Logger = app) {
        guard verboseEnabled else { return }
        logger.debug("\(message, privacy: .public)")
    }

    static func info(_ message: String, logger: Logger = app) {
        logger.info("\(message, privacy: .public)")
    }

    static func error(_ message: String, logger: Logger = app) {
        logger.error("\(message, privacy: .public)")
    }
}
