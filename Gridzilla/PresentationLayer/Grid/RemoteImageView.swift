import SwiftUI
import UIKit

struct RemoteImageView: View {
    enum ContentMode {
        case fill
        case fit
    }

    let url: URL
    let imageLoader: ImageLoader
    var contentMode: ContentMode = .fill

    @State private var uiImage: UIImage?
    @State private var isLoading = false
    @State private var didFail = false
    @State private var loadSequence = 0

    var body: some View {
        ZStack {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: swiftUIContentMode)
                    .transition(.opacity)
            } else if isLoading {
                ProgressView()
            } else {
                placeholder
            }
        }
        .clipped()
        .task(id: loadToken) {
            await loadImage()
        }
    }

    private var loadToken: String {
        "\(url.absoluteString)-\(loadSequence)"
    }

    private var swiftUIContentMode: SwiftUI.ContentMode {
        switch contentMode {
        case .fill: return .fill
        case .fit: return .fit
        }
    }

    private func loadImage() async {
        guard uiImage == nil else { return }
        await MainActor.run {
            isLoading = true
            didFail = false
        }
        do {
            let image = try await imageLoader.loadImage(from: url)
            await MainActor.run { uiImage = image }
        } catch {
            await MainActor.run { didFail = true }
        }
        await MainActor.run { isLoading = false }
    }

    private var placeholder: some View {
        Color.gray.opacity(0.2)
            .overlay {
                if didFail {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.orange)
                        Text("Tap to retry")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Image(systemName: "photo")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { reload() }
    }

    private func reload() {
        guard didFail else { return }
        uiImage = nil
        loadSequence += 1
    }
}
