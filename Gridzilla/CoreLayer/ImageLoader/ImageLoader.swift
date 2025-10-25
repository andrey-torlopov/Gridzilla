import Foundation
import UIKit

actor ImageLoader {
    enum LoaderError: Swift.Error {
        case decodingFailed
    }

    private let networkService: NetworkService
    private let cache: ImageCache
    private var inFlightTasks: [URL: Task<UIImage, Error>] = [:]

    init(networkService: NetworkService, cache: ImageCache) {
        self.networkService = networkService
        self.cache = cache
    }

    func loadImage(from url: URL) async throws -> UIImage {
        if let cached = await cache.image(forKey: url.absoluteString.cacheSafeKey) {
            return cached
        }

        if let task = inFlightTasks[url] {
            return try await task.value
        }

        let task = Task<UIImage, Error> {
            let data = try await networkService.fetchData(from: url)
            guard let image = UIImage(data: data) else { throw LoaderError.decodingFailed }
            await cache.store(image, forKey: url.absoluteString.cacheSafeKey)
            return image
        }

        inFlightTasks[url] = task
        do {
            let image = try await task.value
            inFlightTasks[url] = nil
            return image
        } catch {
            inFlightTasks[url] = nil
            throw error
        }
    }
}
