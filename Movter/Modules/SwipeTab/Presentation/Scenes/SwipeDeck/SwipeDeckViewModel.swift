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

    private let engine: SwipeDeckEngineProtocol
    private let fetchDeckUseCase: FetchPopularSwipeDeckUseCase
    private let swipeCardUseCase: SwipeCardUseCase
    private let getSeenIDsUseCase: GetSeenFilmIDsUseCase
    private let monitor: NetworkMonitoring

    private var queue: [Media] = []
    private var isFetching = false
    private var excludedIDs: Set<Int> = []

    private(set) var sessionSwipeCount = 0
    var isSessionComplete: Bool { sessionSwipeCount >= Self.sessionCardLimit }

    var onQueueChange: (() -> Void)?
    var onError: ((String) -> Void)?

    init(
        engine: SwipeDeckEngineProtocol? = nil,
        fetchDeckUseCase: FetchPopularSwipeDeckUseCase = DefaultFetchPopularSwipeDeckUseCase(),
        swipeCardUseCase: SwipeCardUseCase = DefaultSwipeCardUseCase(),
        getSeenIDsUseCase: GetSeenFilmIDsUseCase = DefaultGetSeenFilmIDsUseCase(),
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.fetchDeckUseCase = fetchDeckUseCase
        self.swipeCardUseCase = swipeCardUseCase
        self.getSeenIDsUseCase = getSeenIDsUseCase
        self.monitor = monitor
        self.engine = engine ?? PFedRecDeckEngine(fetchDeckUseCase: fetchDeckUseCase)
    }

    convenience init(
        watchlistStore: WatchlistStoring,
        seenFilmsStore: SeenFilmsStoring,
        service: MediaFetching = TMDBService.shared,
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.init(
            engine: nil,
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
        Task { [weak self] in
            guard let self = self else { return }
            await self.engine.retryFetchIfNeeded()
            let updated = await self.engine.peek(count: 10)
            await MainActor.run {
                self.queue = updated
                self.onQueueChange?()
            }
        }
    }

    var isExhausted: Bool { queue.isEmpty && !isFetching }

    func peek(_ count: Int) -> [Media] {
        guard !isSessionComplete else { return [] }
        let remaining = Self.sessionCardLimit - sessionSwipeCount
        return Array(queue.prefix(min(count, remaining)))
    }

    func start() {
        guard queue.isEmpty else { return }
        excludedIDs.formUnion(getSeenIDsUseCase.execute())
        isFetching = true

        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.engine.start(excludingIDs: self.excludedIDs)
                let initial = await self.engine.peek(count: 10)
                await MainActor.run {
                    self.isFetching = false
                    self.queue = initial
                    self.onQueueChange?()
                }
            } catch {
                await MainActor.run {
                    self.isFetching = false
                    self.onError?("Couldn't load more films. Check your connection and try again.")
                }
            }
        }
    }

    func consumeFrontCard(direction: SwipeDirection, dwellDuration: TimeInterval = 1.5) {
        guard !queue.isEmpty, !isSessionComplete else { return }
        let media = queue.removeFirst()
        sessionSwipeCount += 1
        excludedIDs.insert(media.id)

        onQueueChange?()

        Task { [weak self] in
            guard let self = self else { return }
            try? await self.swipeCardUseCase.execute(media: media, direction: direction)
            await self.engine.consumeFrontCard(direction: direction, dwellDuration: dwellDuration)
            let updatedPeek = await self.engine.peek(count: 10)

            await MainActor.run {
                self.queue = updatedPeek
                self.onQueueChange?()
            }
        }
    }
}
