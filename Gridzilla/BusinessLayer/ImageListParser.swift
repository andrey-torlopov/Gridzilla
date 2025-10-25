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
        let urls = components.compactMap { URL(string: $0) }.filter { isValidURL($0) }

        if urls.count >= 2 {
            let caption = caption(in: line, removing: urls.map { $0.absoluteString })
            return ImageDescriptor(content: .image(thumbnail: urls[0], original: urls[1], caption: caption))
        } else if let singleURL = urls.first {
            let caption = caption(in: line, removing: [singleURL.absoluteString])
            return ImageDescriptor(content: .image(thumbnail: singleURL, original: singleURL, caption: caption))
        } else if let invalidURL = components.compactMap({ URL(string: $0) }).first {
            return ImageDescriptor(content: .invalidLink(invalidURL.absoluteString))
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

    private func isValidURL(_ url: URL) -> Bool {
        // Check if URL has http or https scheme
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return false
        }

        // Check if URL has a valid host
        guard let host = url.host, !host.isEmpty else {
            return false
        }

        return true
    }

    private func isImageURL(_ url: URL) -> Bool {
        let ext = url.pathExtension.split(separator: "?").first?.lowercased() ?? ""
        return imageExtensions.contains(ext)
    }
}
