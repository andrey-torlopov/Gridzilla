import Foundation

final class ImageRepository {
    private let networkService: NetworkService
    private let textCache: DiskCache
    private let parser: ImageListParser
    private let remoteURL = URL(string: "https://it-link.ru/test/images.txt")!
    private let cacheKey = "images.txt"

    init(networkService: NetworkService, textCache: DiskCache, parser: ImageListParser) {
        self.networkService = networkService
        self.textCache = textCache
        self.parser = parser
    }

    func loadCachedDescriptors() async -> [ImageDescriptor]? {
        guard let data = await textCache.data(for: cacheKey),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return parser.parse(text)
    }

    func refreshDescriptors() async throws -> [ImageDescriptor] {
        let text = try await networkService.fetchText(from: remoteURL)
        try await textCache.store(Data(text.utf8), for: cacheKey)
        return parser.parse(text)
    }
}
