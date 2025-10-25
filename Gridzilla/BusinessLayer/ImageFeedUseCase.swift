import Foundation

struct ImageFeedUseCase {
    private let repository: ImageRepository

    init(repository: ImageRepository) {
        self.repository = repository
    }

    func loadCached() async -> [ImageDescriptor]? {
        await repository.loadCachedDescriptors()
    }

    func refresh() async throws -> [ImageDescriptor] {
        try await repository.refreshDescriptors()
    }
}
