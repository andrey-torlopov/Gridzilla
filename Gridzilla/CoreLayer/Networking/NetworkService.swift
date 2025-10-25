import Foundation

final class NetworkService {
    private let session: URLSession

    init(configuration: URLSessionConfiguration = .default) {
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = URLCache(memoryCapacity: 32 * 1_024 * 1_024,
                                          diskCapacity: 256 * 1_024 * 1_024)
        configuration.timeoutIntervalForRequest = 30
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)
    }

    func fetchText(from url: URL, encoding: String.Encoding = .utf8) async throws -> String {
        let data = try await fetchData(from: url)
        guard let string = String(data: data, encoding: encoding) else {
            throw URLError(.cannotDecodeRawData)
        }
        return string
    }

    func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return data
    }
}
