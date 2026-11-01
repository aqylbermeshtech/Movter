//
//  SwipeDeckViewModel.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import Foundation

final class SwipeDeckViewModel {
    private static let prefetchThreshold = 3
    static let sessionCardLimit = 10

    private let fetchDeckUseCase: FetchPopularSwipeDeckUseCase
    private let swipeCardUseCase: SwipeCardUseCase
    private let getSeenIDsUseCase: GetSeenFilmIDsUseCase
    private let monitor: NetworkMonitoring

    private var queue: [Media] = []
    private var page = 1
    private var isFetching = false
    private var isLastPage = false
    private var excludedIDs: Set<Int> = []

    private(set) var sessionSwipeCount = 0
    var isSessionComplete: Bool { sessionSwipeCount >= Self.sessionCardLimit }

    var onQueueChange: (() -> Void)?
    var onError: ((String) -> Void)?

    init(
        fetchDeckUseCase: FetchPopularSwipeDeckUseCase = DefaultFetchPopularSwipeDeckUseCase(),
        swipeCardUseCase: SwipeCardUseCase = DefaultSwipeCardUseCase(),
        getSeenIDsUseCase: GetSeenFilmIDsUseCase = DefaultGetSeenFilmIDsUseCase(),
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.fetchDeckUseCase = fetchDeckUseCase
        self.swipeCardUseCase = swipeCardUseCase
        self.getSeenIDsUseCase = getSeenIDsUseCase
        self.monitor = monitor
    }

    convenience init(
        watchlistStore: WatchlistStoring,
        seenFilmsStore: SeenFilmsStoring,
        service: MediaFetching = TMDBService.shared,
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.init(
            fetchDeckUseCase: DefaultFetchPopularSwipeDeckUseCase(),
            swipeCardUseCase: DefaultSwipeCardUseCase(),
            getSeenIDsUseCase: DefaultGetSeenFilmIDsUseCase(),
            monitor: monitor
        )
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
        excludedIDs.formUnion(getSeenIDsUseCase.execute())
        fetchNextPage()
    }

    func consumeFrontCard(direction: SwipeDirection) {
        guard !queue.isEmpty, !isSessionComplete else { return }
        let media = queue.removeFirst()
        sessionSwipeCount += 1
        excludedIDs.insert(media.id)

        Task { [weak self] in
            try? await self?.swipeCardUseCase.execute(media: media, direction: direction)
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

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let result = try await self.fetchDeckUseCase.execute(page: self.page, excludingIDs: self.excludedIDs)
                await MainActor.run {
                    self.isFetching = false
                    self.queue.append(contentsOf: result.items)
                    self.isLastPage = result.isLastPage
                    self.page += 1
                    self.onQueueChange?()
                    if self.queue.isEmpty && !self.isLastPage {
                        self.fetchNextPage()
                    }
                }
            } catch {
                await MainActor.run {
                    self.isFetching = false
                    self.onError?("Couldn't load more films. Check your connection and try again.")
                }
            }
        }
    }
}
