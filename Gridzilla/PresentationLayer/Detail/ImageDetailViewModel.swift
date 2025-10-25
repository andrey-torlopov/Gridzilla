import Foundation

@MainActor
final class ImageDetailViewModel: ObservableObject {
    @Published var selection: Int {
        didSet {
            let clamped = clamp(selection)
            if selection != clamped {
                selection = clamped
            }
        }
    }
    let items: [ImageAssetViewModel]
    let imageLoader: ImageLoader

    init(context: ImageDetailContext, imageLoader: ImageLoader) {
        self.items = context.items
        self.selection = min(max(context.initialIndex, 0), context.items.count - 1)
        self.imageLoader = imageLoader
    }

    var currentItem: ImageAssetViewModel {
        items[clamp(selection)]
    }

    func shareURL() -> URL {
        currentItem.originalURL
    }

    func caption(for index: Int) -> String? {
        let index = clamp(index)
        return items[index].caption
    }

    private func clamp(_ index: Int) -> Int {
        guard !items.isEmpty else { return 0 }
        return min(max(index, 0), items.count - 1)
    }
}
