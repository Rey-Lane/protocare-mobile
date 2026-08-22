import SwiftUI
import UIKit
import Combine

/// Loads images from URLs and falls back to a rewritten local-network host when needed.
struct ResilientAsyncImage<Placeholder: View>: View {
    let urlString: String?
    let contentMode: ContentMode
    private let placeholder: Placeholder

    @StateObject private var loader = ResilientAsyncImageLoader()

    init(
        urlString: String?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.urlString = urlString
        self.contentMode = contentMode
        self.placeholder = placeholder()
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
            }
        }
        .task(id: urlString) {
            loader.load(urlString: urlString)
        }
        .onDisappear {
            loader.cancel()
        }
    }
}

@MainActor
final class ResilientAsyncImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?

    private var currentTask: Task<Void, Never>?
    private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 50
        c.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        return c
    }()

    func load(urlString: String?) {
        currentTask?.cancel()

        guard let trimmed = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty,
              let url = URL(string: trimmed) else {
            image = nil
            return
        }

        if let cached = Self.cache.object(forKey: trimmed as NSString) {
            image = cached
            return
        }

        currentTask = Task { [weak self] in
            let downloaded = await Self.downloadImage(from: url)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self else { return }
                if let downloaded {
                    let cost = downloaded.jpegData(compressionQuality: 0.8)?.count ?? 0
                    Self.cache.setObject(downloaded, forKey: trimmed as NSString, cost: cost)
                    self.image = downloaded
                } else {
                    self.image = nil
                }
            }
        }
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    deinit {
        currentTask?.cancel()
    }

    private static func downloadImage(from originalURL: URL) async -> UIImage? {
        if let image = await fetchImage(with: URLRequest(url: originalURL)) {
            return image
        }

        guard let fallbackRequest = makeLoopbackFallbackRequest(from: originalURL) else {
            return nil
        }

        return await fetchImage(with: fallbackRequest)
    }

    private static func fetchImage(with request: URLRequest) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    /// When backend signs MinIO URLs with localhost/127.0.0.1, physical devices cannot reach them.
    /// This rewrites the request host to API host and preserves the original Host header.
    private static func makeLoopbackFallbackRequest(from url: URL) -> URLRequest? {
        guard let originalHost = url.host?.lowercased(),
              isLoopbackHost(originalHost) else {
            return nil
        }

        guard let apiHost = AppEnvironment.current.baseURL.host?.lowercased(),
              !isLoopbackHost(apiHost),
              apiHost != originalHost else {
            return nil
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.host = apiHost

        guard let rewrittenURL = components?.url else {
            return nil
        }

        var request = URLRequest(url: rewrittenURL)
        if let port = url.port {
            request.setValue("\(originalHost):\(port)", forHTTPHeaderField: "Host")
        } else {
            request.setValue(originalHost, forHTTPHeaderField: "Host")
        }
        return request
    }

    private static func isLoopbackHost(_ host: String) -> Bool {
        host == "localhost" || host == "127.0.0.1" || host == "::1"
    }
}
