import Combine
import Foundation

@MainActor
final class ImageGridViewModel: ObservableObject {
    enum ViewState: Equatable {
        case loading
        case loaded(GridSnapshot)
        case failed(String)
    }

    struct GridSnapshot: Equatable {
        var items: [GridCellViewModel]
        var notice: String?
        var lastUpdated: Date
    }

    @Published private(set) var state: ViewState = .loading
    @Published var detailContext: ImageDetailContext?

    private let useCase: ImageFeedUseCase
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    private var descriptors: [ImageDescriptor] = []
    private var hasLoadedOnce = false
    private var isRefreshing = false
    private var shouldRetryOnReconnect = false

    init(useCase: ImageFeedUseCase, networkMonitor: NetworkMonitor) {
        self.useCase = useCase
        self.networkMonitor = networkMonitor
        bindNetworkMonitor()
    }

    func onAppear() {
        guard !hasLoadedOnce else { return }
        hasLoadedOnce = true
        Task { await loadInitial() }
    }

    func userInitiatedRefresh() async {
        await refresh()
    }

    func retry() {
        Task { await refresh() }
    }

    func select(itemWithID id: UUID) {
        guard let descriptor = descriptors.first(where: { $0.id == id }) else { return }
        guard case let .image(_, _, _) = descriptor.content else { return }
        let imageItems = descriptors.compactMap { descriptor -> ImageAssetViewModel? in
            guard case let .image(thumbnail, original, caption) = descriptor.content else { return nil }
            return ImageAssetViewModel(id: descriptor.id, thumbnailURL: thumbnail, originalURL: original, caption: caption)
        }
        guard let startIndex = imageItems.firstIndex(where: { $0.id == descriptor.id }) else { return }
        detailContext = ImageDetailContext(items: imageItems, initialIndex: startIndex)
    }

    private func loadInitial() async {
        if let cached = await useCase.loadCached() {
            applySnapshot(with: cached, notice: nil)
        } else {
            state = .loading
        }
        await refresh()
    }

    private func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let descriptors = try await useCase.refresh()
            shouldRetryOnReconnect = false
            applySnapshot(with: descriptors, notice: nil)
        } catch {
            handle(error: error)
        }
    }

    private func applySnapshot(with descriptors: [ImageDescriptor], notice: String?) {
        self.descriptors = descriptors
        let items = descriptors.map(GridCellViewModel.init(descriptor:))
        let snapshot = GridSnapshot(items: items, notice: notice, lastUpdated: Date())
        state = .loaded(snapshot)
    }

    private func handle(error: Swift.Error) {
        shouldRetryOnReconnect = shouldRetry(for: error)
        let message = errorMessage(from: error)

        if case .loaded(var snapshot) = state {
            snapshot.notice = message
            state = .loaded(snapshot)
        } else if !descriptors.isEmpty {
            let items = descriptors.map(GridCellViewModel.init(descriptor:))
            let snapshot = GridSnapshot(items: items, notice: message, lastUpdated: Date())
            state = .loaded(snapshot)
        } else {
            state = .failed(message)
        }
    }

    private func bindNetworkMonitor() {
        networkMonitor.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self else { return }
                if isConnected && self.shouldRetryOnReconnect {
                    self.shouldRetryOnReconnect = false
                    Task { await self.refresh() }
                }
            }
            .store(in: &cancellables)
    }

    private func shouldRetry(for error: Swift.Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .networkConnectionLost, .notConnectedToInternet, .timedOut, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }

    private func errorMessage(from error: Swift.Error) -> String {
        if let urlError = error as? URLError {
            return urlError.localizedDescription
        }
        return error.localizedDescription
    }
}
