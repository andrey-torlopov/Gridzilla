import SwiftUI

struct ImageDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ImageDetailViewModel
    @State private var isChromeVisible = true

    init(viewModel: ImageDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                TabView(selection: $viewModel.selection) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        ZoomableRemoteImage(url: item.originalURL,
                                            imageLoader: viewModel.imageLoader,
                                            isChromeVisible: $isChromeVisible)
                            .tag(index)
                            .overlay(alignment: .bottomLeading) {
                                if let caption = viewModel.caption(for: index), isChromeVisible {
                                    captionLabel(caption)
                                }
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toolbar(isChromeVisible ? .visible : .hidden, for: .navigationBar)
            .statusBarHidden(!isChromeVisible)
        }
    }

    private func captionLabel(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.black.opacity(0.6), in: Capsule())
            .foregroundColor(.white)
            .padding([.leading, .bottom], 24)
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
            }
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            ShareLink(item: viewModel.shareURL())
        }
    }
}

private struct ZoomableRemoteImage: View {
    let url: URL
    let imageLoader: ImageLoader
    @Binding var isChromeVisible: Bool

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        RemoteImageView(url: url, imageLoader: imageLoader, contentMode: .fit)
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(zoomGesture)
            .onTapGesture { isChromeVisible.toggle() }
            .onTapGesture(count: 2) { toggleZoom() }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scale)
            .animation(.easeInOut(duration: 0.2), value: isChromeVisible)
    }

    private var zoomGesture: some Gesture {
        SimultaneousGesture(magnificationGesture, dragGesture)
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = clampScale(lastScale * value)
                scale = newScale
            }
            .onEnded { _ in
                lastScale = clampScale(scale)
                if scale <= 1 { resetZoom() }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(width: lastOffset.width + value.translation.width,
                                 height: lastOffset.height + value.translation.height)
            }
            .onEnded { _ in
                guard scale > 1 else { return }
                lastOffset = offset
            }
    }

    private func toggleZoom() {
        withAnimation(.spring()) {
            if scale > 1.5 {
                resetZoom()
            } else {
                scale = 2.5
            }
        }
    }

    private func clampScale(_ value: CGFloat) -> CGFloat {
        min(max(value, 1), 5)
    }

    private func resetZoom() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }
}
