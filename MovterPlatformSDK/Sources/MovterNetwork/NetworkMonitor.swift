//
//  NetworkMonitor.swift
//  MovterNetwork
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation
import Network

public protocol NetworkMonitoring: AnyObject {
    var isOnline: Bool { get }
}

public final class NetworkMonitor: NetworkMonitoring {

    public static let shared = NetworkMonitor()

    public static let connectivityDidChangeNotification = Notification.Name("NetworkConnectivityDidChange")

    public private(set) var isOnline = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.nurtore.movter.networkmonitor")

    public init() {
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
