//
//  NetworkMonitor.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation
import Network

/// Whether the device currently has a usable network path.
///
/// Deliberately separate from request failures. A request can fail for reasons that
/// have nothing to do with connectivity, and the device can be offline before any
/// request is made — so screens use this to say *why* there is nothing to show instead
/// of guessing "check your connection" after every failure.
protocol NetworkMonitoring: AnyObject {
    var isOnline: Bool { get }
}

final class NetworkMonitor: NetworkMonitoring {

    static let shared = NetworkMonitor()

    /// Posted on the main actor when connectivity flips — not on every path update.
    /// A notification rather than a closure because several screens observe at once,
    /// the same way `ThemeManager` broadcasts theme changes.
    static let connectivityDidChangeNotification = Notification.Name("NetworkConnectivityDidChange")

    /// Optimistic until the first path update lands. `NWPathMonitor` takes a moment to
    /// report, and flashing an offline placeholder over a working connection is worse
    /// than being briefly, invisibly wrong in the other direction.
    private(set) var isOnline = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.nurtore.movter.networkmonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            // The handler runs on `queue`; the state it updates is main-actor.
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
