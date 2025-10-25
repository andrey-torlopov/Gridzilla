import SwiftUI

struct RootView: View {
    private let dependencies = AppDependencies.make()

    var body: some View {
        ImageGridView(viewModel: dependencies.makeImageGridViewModel(),
                      imageLoader: dependencies.imageLoader)
    }
}

#Preview {
    RootView()
}
