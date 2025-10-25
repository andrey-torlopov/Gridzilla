import Foundation

struct ImageListParser {
    private let imageExtensions = Set(["jpg", "jpeg", "png", "gif", "webp"])

    func parse(_ text: String) -> [ImageDescriptor] {
        text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map(makeDescriptor(from:))
    }

    private func makeDescriptor(from line: String) -> ImageDescriptor {
        let components = tokenize(line: line)
        let urls = components.compactMap { URL(string: $0) }
        let imageURLs = urls.filter { isImageURL($0) }

        if imageURLs.count >= 2 {
            let caption = caption(in: line, removing: imageURLs.map { $0.absoluteString })
            return ImageDescriptor(content: .image(thumbnail: imageURLs[0], original: imageURLs[1], caption: caption))
        } else if let singleImage = imageURLs.first {
            let caption = caption(in: line, removing: [singleImage.absoluteString])
            return ImageDescriptor(content: .image(thumbnail: singleImage, original: singleImage, caption: caption))
        } else if let url = urls.first {
            return ImageDescriptor(content: .invalidLink(url.absoluteString))
        } else {
            return ImageDescriptor(content: .text(line))
        }
    }

    private func tokenize(line: String) -> [String] {
        line.components(separatedBy: CharacterSet(charactersIn: " \t,;|"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func caption(in line: String, removing urlStrings: [String]) -> String? {
        var caption = line
        for urlString in urlStrings {
            caption = caption.replacingOccurrences(of: urlString, with: "")
        }
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func isImageURL(_ url: URL) -> Bool {
        let ext = url.pathExtension.split(separator: "?").first?.lowercased() ?? ""
        return imageExtensions.contains(ext)
    }
}
