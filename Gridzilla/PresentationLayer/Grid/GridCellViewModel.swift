import Foundation

struct GridCellViewModel: Identifiable, Equatable {
    enum Kind: Equatable {
        case image(ImageAssetViewModel)
        case text(String)
        case invalid(String)
    }

    let id: UUID
    let title: String?
    let kind: Kind

    init(descriptor: ImageDescriptor) {
        id = descriptor.id
        switch descriptor.content {
        case let .image(thumbnail, original, caption):
            title = caption
            let asset = ImageAssetViewModel(id: descriptor.id,
                                            thumbnailURL: thumbnail,
                                            originalURL: original,
                                            caption: caption)
            kind = .image(asset)
        case let .text(text):
            title = text
            kind = .text(text)
        case let .invalidLink(link):
            title = link
            kind = .invalid(link)
        }
    }
}

struct ImageAssetViewModel: Identifiable, Equatable {
    let id: UUID
    let thumbnailURL: URL
    let originalURL: URL
    let caption: String?
}

struct ImageDetailContext: Identifiable, Equatable {
    let id = UUID()
    let items: [ImageAssetViewModel]
    let initialIndex: Int
}
