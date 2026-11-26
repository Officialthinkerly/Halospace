//
//  HaloLinkParser.swift
//  HaloSpace V3
//

import Foundation

enum HaloLinkParser {
    static func normalizedURL(from input: String, searchEngine: HaloSearchEngine) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let direct = URL(string: trimmed), let scheme = direct.scheme?.lowercased(),
           scheme == "http" || scheme == "https",
           direct.host?.isEmpty == false {
            return direct
        }

        let looksLikeHost = trimmed.contains(".")
            && !trimmed.contains(" ")
            && !trimmed.hasPrefix(".")
            && !trimmed.hasSuffix(".")

        if looksLikeHost, let url = URL(string: "https://\(trimmed)"), url.host?.isEmpty == false {
            return url
        }

        return searchEngine.searchURL(trimmed)
    }

    static func displayHost(for url: URL?) -> String {
        guard let url else { return "New Tab" }
        if let host = url.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return url.absoluteString
    }

    static func isSecure(_ url: URL?) -> Bool {
        url?.scheme?.lowercased() == "https"
    }

    static func validatedWebAppURL(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard
            let url = URL(string: candidate),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            url.host?.isEmpty == false
        else { return nil }
        return url
    }
}
