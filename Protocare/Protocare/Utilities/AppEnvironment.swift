//
//  Environment.swift
//  Protocare
//
//  Environment configuration for different build targets
//

import Foundation

enum AppEnvironment {
    case local(ip: String)
    case staging
    case production

    var baseURL: URL {
        let url: URL
        switch self {
        case .local(let ip):
            url = URL(string: "http://\(ip):8000/v1")!
        case .staging:
            url = URL(string: "https://staging-api.protocare.com/v1")!
        case .production:
            url = URL(string: "https://api.protocare.com/v1")!
        }

        // S-04: Crash in release builds if an HTTP (non-HTTPS) URL would be
        // used in production. Local development with HTTP is allowed in DEBUG.
        #if !DEBUG
        if url.scheme == "http" {
            fatalError("🔴 Insecure HTTP URL detected in production build: \(url.absoluteString). All production endpoints must use HTTPS.")
        }
        #endif

        return url
    }

    /// Current environment - reads from Info.plist which is configured via xcconfig
    static var current: AppEnvironment {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              let url = URL(string: urlString) else {
            // Fallback to local development
            return .local(ip: "192.168.1.71")
        }

        // Determine environment based on URL
        if urlString.contains("localhost") || urlString.contains("192.168.") || urlString.contains("127.0.0.1") {
            let ip = urlString.replacingOccurrences(of: "http://", with: "")
                .replacingOccurrences(of: ":8000/v1", with: "")
                .replacingOccurrences(of: ":8000", with: "")
            return .local(ip: ip)
        } else if urlString.contains("staging") {
            return .staging
        } else {
            return .production
        }
    }
}
