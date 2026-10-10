//
//  NetworkMonitor.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation
import Network

protocol NetworkMonitoring: AnyObject {
    var isOnline: Bool { get }
}

final class NetworkMonitor: NetworkMonitoring {

    static let shared = NetworkMonitor()

    static let connectivityDidChangeNotification = Notification.Name("NetworkConnectivityDidChange")

    private(set) var isOnline = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.nurtore.movter.networkmonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in
                guard let self, self.isOnline != online else { return }
                self.isOnline = online
                NotificationCenter.default.post(
                    name: Self.connectivityDidChangeNotification,
                    object: nil
                )
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
