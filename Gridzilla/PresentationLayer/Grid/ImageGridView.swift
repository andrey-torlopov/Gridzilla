import SwiftUI

struct ImageGridView: View {
    @StateObject private var viewModel: ImageGridViewModel
    private let imageLoader: ImageLoader

    init(viewModel: @autoclosure @escaping () -> ImageGridViewModel, imageLoader: ImageLoader) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.imageLoader = imageLoader
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                content
            }
            .navigationTitle("Gridzilla")
            .toolbar { refreshToolbar }
        }
        .task { viewModel.onAppear() }
        .fullScreenCover(item: $viewModel.detailContext) { context in
            ImageDetailView(viewModel: ImageDetailViewModel(context: context, imageLoader: imageLoader))
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().controlSize(.large)
        case let .failed(message):
            ErrorStateView(message: message, retry: viewModel.retry)
        case let .loaded(snapshot):
            grid(for: snapshot)
        }
    }

    private var refreshToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task { await viewModel.userInitiatedRefresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .accessibilityLabel("Refresh")
        }
    }

    private func grid(for snapshot: ImageGridViewModel.GridSnapshot) -> some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: columns(for: geometry.size.width), spacing: 12) {
                    ForEach(snapshot.items) { item in
                        GridCellView(model: item, imageLoader: imageLoader, retry: viewModel.retry)
                            .onTapGesture { viewModel.select(itemWithID: item.id) }
                    }
                }
                .padding(12)
            }
            .refreshable { await viewModel.userInitiatedRefresh() }
            .background(Color(.systemBackground))
            .overlay(alignment: .top) {
                if let notice = snapshot.notice {
                    NoticeBanner(text: notice)
                        .padding(.top, 12)
                }
            }
        }
    }

    private func columns(for width: CGFloat) -> [GridItem] {
        let minWidth: CGFloat = 140
        let spacing: CGFloat = 12
        let count = max(Int((width + spacing) / (minWidth + spacing)), 1)
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }
}

private struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
            Text(message)
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private struct NoticeBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(radius: 3)
    }
}
