//
//  SwipeDeckViewModel.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import Foundation

enum SwipeDirection {
    case like
    case pass
}

final class SwipeDeckViewModel {
    private static let prefetchThreshold = 3
    static let sessionCardLimit = 10

    private let watchlistStore: WatchlistStoring
    private let seenFilmsStore: SeenFilmsStoring
    private var queue: [Media] = []
    private var page = 1
    private var isFetching = false
    private var isLastPage = false
    private var excludedIDs: Set<Int> = []

    private(set) var sessionSwipeCount = 0
    var isSessionComplete: Bool { sessionSwipeCount >= Self.sessionCardLimit }

    var onQueueChange: (() -> Void)?
    var onError: ((String) -> Void)?

    private let service: MediaFetching
    private let monitor: NetworkMonitoring

    init(
        watchlistStore: WatchlistStoring,
        seenFilmsStore: SeenFilmsStoring,
        service: MediaFetching = TMDBService.shared,
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.watchlistStore = watchlistStore
        self.seenFilmsStore = seenFilmsStore
        self.service = service
        self.monitor = monitor
    }
    var isOffline: Bool { !monitor.isOnline }

    func connectivityDidChange() {
        guard monitor.isOnline else {
            onQueueChange?()
            return
        }
        fetchNextPage()
    }

    var isExhausted: Bool { queue.isEmpty && isLastPage && !isFetching }
    func peek(_ count: Int) -> [Media] {
        guard !isSessionComplete else { return [] }
        let remaining = Self.sessionCardLimit - sessionSwipeCount
        return Array(queue.prefix(min(count, remaining)))
    }

    func start() {
        guard queue.isEmpty else { return }
        seenFilmsStore.fetchIDs { [weak self] ids in
            guard let self = self else { return }
            self.excludedIDs.formUnion(ids)
            self.fetchNextPage()
        }
    }

    func consumeFrontCard(direction: SwipeDirection) {
        guard !queue.isEmpty, !isSessionComplete else { return }
        let media = queue.removeFirst()
        sessionSwipeCount += 1
        excludedIDs.insert(media.id)
        seenFilmsStore.markSeen(media.id)
        if direction == .like {
            watchlistStore.save(WatchlistItem(from: media)) { _ in            }
        }
        if !isSessionComplete && queue.count <= Self.prefetchThreshold {
            fetchNextPage()
        }
        onQueueChange?()
    }

    private func fetchNextPage() {
        guard !isFetching, !isLastPage, !isSessionComplete else { return }
        guard monitor.isOnline else {
            onQueueChange?()
            return
        }
        isFetching = true
        service.fetchPopularMovies(page: page) { [weak self] result in
            guard let self = self else { return }
            self.isFetching = false
            guard let result = result else {
                self.onError?("Couldn't load more films. Check your connection and try again.")
                return
            }
            let fresh = result.items.filter { !self.excludedIDs.contains($0.id) }
            self.queue.append(contentsOf: fresh)
            self.isLastPage = result.isLastPage
            self.page += 1
            self.onQueueChange?()
            if self.queue.isEmpty && !self.isLastPage {
                self.fetchNextPage()
            }
        }
    }
}
