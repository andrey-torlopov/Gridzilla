import Combine
import Foundation
import Network

final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected: Bool = true

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.gridzilla.network-monitor")

    var statusPublisher: AnyPublisher<Bool, Never> {
        $isConnected.removeDuplicates().eraseToAnyPublisher()
    }

    init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
