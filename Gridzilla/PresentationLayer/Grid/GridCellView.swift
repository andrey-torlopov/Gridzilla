import SwiftUI

struct GridCellView: View {
    let model: GridCellViewModel
    let imageLoader: ImageLoader
    let retry: () -> Void

    var body: some View {
        ZStack {
            switch model.kind {
            case let .image(asset):
                RemoteImageView(url: asset.thumbnailURL, imageLoader: imageLoader)
                    .overlay(alignment: .bottomLeading) {
                        if let caption = asset.caption {
                            captionView(text: caption)
                        }
                    }
            case let .text(text):
                labelView(icon: "doc.text", text: text)
            case let .invalid(link):
                labelView(icon: "exclamationmark.triangle", text: link)
                    .overlay(alignment: .topTrailing) {
                        Button(action: retry) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .padding(8)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    private func captionView(text: String) -> some View {
        Text(text)
            .font(.footnote)
            .lineLimit(2)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [Color.black.opacity(0.65), Color.clear], startPoint: .bottom, endPoint: .top)
            )
            .foregroundColor(.white)
    }

    private func labelView(icon: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
            Text(text)
                .multilineTextAlignment(.center)
                .font(.footnote)
                .foregroundStyle(Color.secondary)
        }
        .padding()
    }
}
