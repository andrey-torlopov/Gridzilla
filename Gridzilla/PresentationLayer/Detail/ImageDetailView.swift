import SwiftUI

struct ImageDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ImageDetailViewModel
    @State private var isChromeVisible = true
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

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
                                            isChromeVisible: $isChromeVisible,
                                            isDragging: $isDragging)
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
            .offset(y: dragOffset)
            .gesture(dismissGesture)
            .opacity(isDragging ? 1 - abs(dragOffset) / 400.0 : 1)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toolbar(isChromeVisible ? .visible : .hidden, for: .navigationBar)
            .statusBarHidden(!isChromeVisible)
        }
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard !isDragging else { return }
                // Only allow vertical drag down when not zoomed
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                guard !isDragging else { return }
                // Dismiss if dragged down more than 150 points
                if value.translation.height > 150 {
                    dismiss()
                } else {
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white, .black.opacity(0.5))
            }
            .accessibilityLabel("Close")
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            ShareLink(item: viewModel.shareURL()) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white, .black.opacity(0.5))
            }
            .accessibilityLabel("Share")
        }
    }
}

private struct ZoomableRemoteImage: View {
    let url: URL
    let imageLoader: ImageLoader
    @Binding var isChromeVisible: Bool
    @Binding var isDragging: Bool

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
            .onChange(of: scale) { _, newScale in
                isDragging = newScale > 1
            }
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
