//
//  HaloBrand.swift
//  HaloSpace V3
//

import Foundation

enum HaloBrand {
    static let name = "HaloSpace"
    static let version = "3.0"
    static let tagline = "Step into a larger workspace."
    static let shortDescription = "A spatial experience, reimagined."
    static let longDescription = "HaloSpace turns your iPhone into a quiet spatial workspace. Bring your apps into the world around you and work with a larger canvas."

    static var versionLabel: String { "v\(version)" }

    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.halospace.v3"
    }

    static var privacyURL: URL? {
        URL(string: "https://halospace.app/privacy")
    }
}
