import CryptoKit
import Foundation

extension String {
    var cacheSafeKey: String {
        let digest = SHA256.hash(data: Data(utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
