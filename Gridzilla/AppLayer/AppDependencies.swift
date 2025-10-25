import Foundation

struct AppDependencies {
    let networkService: NetworkService
    let textCache: DiskCache
    let imageCache: ImageCache
    let imageLoader: ImageLoader
    let repository: ImageRepository
    let useCase: ImageFeedUseCase
    let networkMonitor: NetworkMonitor

    static func make() -> AppDependencies {
        let networkService = NetworkService()
        let textCache = DiskCache(directoryName: "text-cache")
        let imageDiskCache = DiskCache(directoryName: "image-cache")
        let imageCache = ImageCache(memoryLimit: 64 * 1_024 * 1_024, diskCache: imageDiskCache)
        let imageLoader = ImageLoader(networkService: networkService, cache: imageCache)
        let parser = ImageListParser()
        let repository = ImageRepository(networkService: networkService,
                                         textCache: textCache,
                                         parser: parser)
        let useCase = ImageFeedUseCase(repository: repository)
        let networkMonitor = NetworkMonitor()

        return AppDependencies(networkService: networkService,
                               textCache: textCache,
                               imageCache: imageCache,
                               imageLoader: imageLoader,
                               repository: repository,
                               useCase: useCase,
                               networkMonitor: networkMonitor)
    }

    func makeImageGridViewModel() -> ImageGridViewModel {
        ImageGridViewModel(useCase: useCase, networkMonitor: networkMonitor)
    }
}
