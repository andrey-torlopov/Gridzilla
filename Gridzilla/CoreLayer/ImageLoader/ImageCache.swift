import Foundation
import UIKit

final class ImageCache {
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache: DiskCache

    init(memoryLimit: Int, diskCache: DiskCache) {
        memoryCache.totalCostLimit = memoryLimit
        self.diskCache = diskCache
    }

    func image(forKey key: String) async -> UIImage? {
        if let memoryImage = memoryCache.object(forKey: key as NSString) {
            return memoryImage
        }

        guard let data = await diskCache.data(for: key), let image = UIImage(data: data) else {
            return nil
        }

        memoryCache.setObject(image, forKey: key as NSString)
        return image
    }

    func store(_ image: UIImage, forKey key: String) async {
        memoryCache.setObject(image, forKey: key as NSString)
        guard let data = image.pngData() ?? image.jpegData(compressionQuality: 0.95) else { return }
        try? await diskCache.store(data, for: key)
    }
}
