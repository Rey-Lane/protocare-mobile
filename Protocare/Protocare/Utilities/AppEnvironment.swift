//
//  Environment.swift
//  Protocare
//
//  Environment configuration for different build targets
//

import Foundation

enum AppEnvironment {
    case local(ip: String)
    case production

    var baseURL: URL {
        let url: URL
        switch self {
        case .local(let ip):
            url = URL(string: "http://\(ip):8000/v1")!
        case .production:
            url = URL(string: "https://api.protocare.dev/v1")!
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

    /// Current environment - selected at compile time.
    ///
    /// Note: `Config/*.xcconfig` files are NOT wired into the Xcode project
    /// (no baseConfigurationReference, and GENERATE_INFOPLIST_FILE emits no
    /// API_BASE_URL key), so the previous Info.plist-based detection never
    /// worked - it always fell back to the local IP. Keep URL selection here
    /// until the xcconfig chain is properly wired.
    static var current: AppEnvironment {
        #if DEBUG
        // Debug builds target the deployed backend by default.
        // To run against a local backend on the Mac: .local(ip: "192.168.1.71")
        return .production
        #else
        return .production
        #endif
    }
}
