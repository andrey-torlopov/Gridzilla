import Foundation

struct ImageDescriptor: Identifiable, Equatable {
    enum Content: Equatable {
        case image(thumbnail: URL, original: URL, caption: String?)
        case text(String)
        case invalidLink(String)
    }

    let id: UUID
    let content: Content

    init(id: UUID = UUID(), content: Content) {
        self.id = id
        self.content = content
    }
}
