import Foundation

actor DiskCache {
    enum Error: Swift.Error {
        case directoryCreationFailed
    }

    private let directoryURL: URL
    private let fileManager: FileManager

    init(directoryName: String, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let baseURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directoryURL = baseURL.appendingPathComponent("com.gridzilla.cache").appendingPathComponent(directoryName, isDirectory: true)
        self.directoryURL = directoryURL
        ensureDirectoryExists()
    }

    func store(_ data: Data, for key: String) async throws {
        let url = fileURL(for: key)
        let parent = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parent.path) {
            try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        }
        try data.write(to: url, options: .atomic)
    }

    func data(for key: String) async -> Data? {
        let url = fileURL(for: key)
        return try? Data(contentsOf: url)
    }

    func removeValue(for key: String) async {
        let url = fileURL(for: key)
        try? fileManager.removeItem(at: url)
    }

    func clear() async {
        guard fileManager.fileExists(atPath: directoryURL.path) else { return }
        try? fileManager.removeItem(at: directoryURL)
        ensureDirectoryExists()
    }

    private func fileURL(for key: String) -> URL {
        directoryURL.appendingPathComponent(key)
    }

    private func ensureDirectoryExists() {
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }
}
