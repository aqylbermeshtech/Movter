//
//  SwipeDeckViewModel.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import Foundation

@MainActor
final class SwipeDeckViewModel {
    private static let prefetchThreshold = 3
    static let sessionCardLimit = 10

    private let fetchDeckUseCase: FetchPopularSwipeDeckUseCase
    private let swipeCardUseCase: SwipeCardUseCase
    private let getExcludedIDsUseCase: GetExcludedSwipeMediaIDsUseCase
    private let monitor: NetworkMonitoring

    private(set) var queue: [Media] = []
    private var page = 1
    private(set) var isFetching = false
    private(set) var isLastPage = false
    private(set) var excludedIDs: Set<Int> = []
    private var sessionSwipedIDs: Set<Int> = []
    private var isStarting = false
    private var hasLoadedInitialExclusions = false
    private var reconcileTask: Task<Void, Never>?

    private(set) var sessionSwipeCount = 0
    var isSessionComplete: Bool { sessionSwipeCount >= Self.sessionCardLimit }

    var onQueueChange: (() -> Void)?
    var onError: ((String) -> Void)?

    init(
        fetchDeckUseCase: FetchPopularSwipeDeckUseCase = DefaultFetchPopularSwipeDeckUseCase(),
        swipeCardUseCase: SwipeCardUseCase = DefaultSwipeCardUseCase(),
        getExcludedIDsUseCase: GetExcludedSwipeMediaIDsUseCase = DefaultGetExcludedSwipeMediaIDsUseCase(),
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.fetchDeckUseCase = fetchDeckUseCase
        self.swipeCardUseCase = swipeCardUseCase
        self.getExcludedIDsUseCase = getExcludedIDsUseCase
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
            getExcludedIDsUseCase: DefaultGetExcludedSwipeMediaIDsUseCase(),
            monitor: monitor
        )
    }

    convenience init(
        fetchDeckUseCase: FetchPopularSwipeDeckUseCase = DefaultFetchPopularSwipeDeckUseCase(),
        swipeCardUseCase: SwipeCardUseCase = DefaultSwipeCardUseCase(),
        getSeenIDsUseCase: GetSeenFilmIDsUseCase,
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.init(
            fetchDeckUseCase: fetchDeckUseCase,
            swipeCardUseCase: swipeCardUseCase,
            getExcludedIDsUseCase: SeenIDsExclusionAdapter(useCase: getSeenIDsUseCase),
            monitor: monitor
        )
    }

    var isOffline: Bool { !monitor.isOnline }

    func connectivityDidChange() {
        guard monitor.isOnline else {
            onQueueChange?()
            return
        }
        guard hasLoadedInitialExclusions else {
            if !isStarting && queue.isEmpty {
                start()
            }
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
        guard !isStarting, !hasLoadedInitialExclusions, queue.isEmpty else { return }
        isStarting = true

        Task { [weak self] in
            guard let self else { return }
            let excluded = await self.getExcludedIDsUseCase.execute()
            self.excludedIDs = excluded.union(self.sessionSwipedIDs)
            self.hasLoadedInitialExclusions = true
            self.isStarting = false
            self.fetchNextPage()
        }
    }

    func reconcileQueueWithLatestExclusions() {
        guard hasLoadedInitialExclusions, !isStarting else { return }
        reconcileTask?.cancel()
        reconcileTask = Task { [weak self] in
            await self?.performQueueReconciliation()
        }
    }

    func performQueueReconciliation() async {
        guard hasLoadedInitialExclusions, !isStarting else { return }
        let latestExcluded = await getExcludedIDsUseCase.execute()
        guard !Task.isCancelled else { return }

        excludedIDs = latestExcluded.union(sessionSwipedIDs)

        let originalCount = queue.count
        queue.removeAll { excludedIDs.contains($0.id) }
        let removedAny = queue.count != originalCount

        if !isSessionComplete && queue.count <= Self.prefetchThreshold {
            fetchNextPage()
        }

        if removedAny {
            onQueueChange?()
        }
    }

    func consumeFrontCard(direction: SwipeDirection) {
        guard !queue.isEmpty, !isSessionComplete else { return }
        let media = queue.removeFirst()
        sessionSwipeCount += 1
        sessionSwipedIDs.insert(media.id)
        excludedIDs.insert(media.id)

        Task { [weak self] in
            try? await self?.swipeCardUseCase.execute(media: media, direction: direction)
        }

        let remainingInSession = Self.sessionCardLimit - sessionSwipeCount
        if !isSessionComplete && queue.count <= Self.prefetchThreshold && queue.count < remainingInSession {
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
                self.isFetching = false
                let existingQueueIDs = Set(self.queue.map(\.id))
                let freshItems = result.items.filter {
                    !self.excludedIDs.contains($0.id) && !existingQueueIDs.contains($0.id)
                }
                self.queue.append(contentsOf: freshItems)
                self.isLastPage = result.isLastPage
                self.page += 1
                self.onQueueChange?()
                if self.queue.isEmpty && !self.isLastPage {
                    self.fetchNextPage()
                }
            } catch {
                self.isFetching = false
                self.onError?("Couldn't load more films. Check your connection and try again.")
            }
        }
    }
}

private final class SeenIDsExclusionAdapter: GetExcludedSwipeMediaIDsUseCase {
    private let useCase: GetSeenFilmIDsUseCase

    init(useCase: GetSeenFilmIDsUseCase) {
        self.useCase = useCase
    }

    func execute() async -> Set<Int> {
        useCase.execute().filter { $0 > 0 }
    }
}
