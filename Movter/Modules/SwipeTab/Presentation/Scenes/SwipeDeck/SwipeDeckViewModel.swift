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
    static let maxConsecutiveEmptyPages = 3

    private let fetchDeckUseCase: FetchPopularSwipeDeckUseCase
    private let swipeCardUseCase: SwipeCardUseCase
    private let getExcludedIDsUseCase: GetExcludedSwipeMediaIDsUseCase
    private let buildTasteProfileUseCase: BuildUserTasteProfileUseCase
    private let undoSwipeCardUseCase: UndoSwipeCardUseCase
    private let artworkPrefetcher: HeroArtworkPrefetching?
    private let monitor: NetworkMonitoring
    private let paginationCursorStore: SwipePaginationCursorStoring

    private(set) var queue: [Media] = []
    private(set) var tasteProfile: UserTasteProfile = .empty
    private var page: Int
    private var consecutiveEmptyPages = 0
    private(set) var isFetching = false
    private(set) var isLastPage = false
    private(set) var excludedIDs: Set<Int> = []
    private var sessionSwipedIDs: Set<Int> = []
    private var prefetchedArtworkIDs: Set<Int> = []
    private var isStarting = false
    private var hasLoadedInitialExclusions = false
    private var reconcileTask: Task<Void, Never>?
    private var persistenceTask: Task<Void, Never>?

    private(set) var sessionSwipeCount = 0
    private(set) var sessionLikesCount = 0
    private(set) var lastSwipedCard: (media: Media, direction: SwipeDirection)?
    var canUndo: Bool { lastSwipedCard != nil }
    var isSessionComplete: Bool { sessionSwipeCount >= Self.sessionCardLimit }

    var onQueueChange: (() -> Void)?
    var onError: ((String) -> Void)?

    init(
        fetchDeckUseCase: FetchPopularSwipeDeckUseCase = DefaultFetchPopularSwipeDeckUseCase(),
        swipeCardUseCase: SwipeCardUseCase = DefaultSwipeCardUseCase(),
        getExcludedIDsUseCase: GetExcludedSwipeMediaIDsUseCase = DefaultGetExcludedSwipeMediaIDsUseCase(),
        buildTasteProfileUseCase: BuildUserTasteProfileUseCase = DefaultBuildUserTasteProfileUseCase(),
        monitor: NetworkMonitoring = NetworkMonitor.shared,
        paginationCursorStore: SwipePaginationCursorStoring = UserDefaultsSwipePaginationCursorStore(),
        undoSwipeCardUseCase: UndoSwipeCardUseCase = DefaultUndoSwipeCardUseCase(),
        artworkPrefetcher: HeroArtworkPrefetching? = DefaultHeroArtworkPrefetcher()
    ) {
        self.fetchDeckUseCase = fetchDeckUseCase
        self.swipeCardUseCase = swipeCardUseCase
        self.getExcludedIDsUseCase = getExcludedIDsUseCase
        self.buildTasteProfileUseCase = buildTasteProfileUseCase
        self.monitor = monitor
        self.paginationCursorStore = paginationCursorStore
        self.undoSwipeCardUseCase = undoSwipeCardUseCase
        self.artworkPrefetcher = artworkPrefetcher
        self.page = paginationCursorStore.loadPageCursor()
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
        monitor: NetworkMonitoring = NetworkMonitor.shared,
        paginationCursorStore: SwipePaginationCursorStoring = UserDefaultsSwipePaginationCursorStore(),
        undoSwipeCardUseCase: UndoSwipeCardUseCase = DefaultUndoSwipeCardUseCase(),
        artworkPrefetcher: HeroArtworkPrefetching? = DefaultHeroArtworkPrefetcher()
    ) {
        self.init(
            fetchDeckUseCase: fetchDeckUseCase,
            swipeCardUseCase: swipeCardUseCase,
            getExcludedIDsUseCase: SeenIDsExclusionAdapter(useCase: getSeenIDsUseCase),
            monitor: monitor,
            paginationCursorStore: paginationCursorStore,
            undoSwipeCardUseCase: undoSwipeCardUseCase,
            artworkPrefetcher: artworkPrefetcher
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
            async let excluded = self.getExcludedIDsUseCase.execute()
            async let profile = self.buildTasteProfileUseCase.execute()
            let (resolvedExcluded, resolvedProfile) = await (excluded, profile)
            self.excludedIDs = resolvedExcluded.union(self.sessionSwipedIDs)
            self.tasteProfile = resolvedProfile
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
            prefetchArtworkForUpcomingCards()
            onQueueChange?()
        }
    }

    func consumeFrontCard(direction: SwipeDirection) {
        guard !queue.isEmpty, !isSessionComplete else { return }
        let media = queue.removeFirst()
        lastSwipedCard = (media: media, direction: direction)
        sessionSwipeCount += 1
        if direction == .like {
            sessionLikesCount += 1
        }
        sessionSwipedIDs.insert(media.id)
        excludedIDs.insert(media.id)
        tasteProfile.applySessionSwipe(media: media, direction: direction)

        let previousTask = persistenceTask
        persistenceTask = Task { [weak self] in
            await previousTask?.value
            try? await self?.swipeCardUseCase.execute(media: media, direction: direction)
        }

        let remainingInSession = Self.sessionCardLimit - sessionSwipeCount
        if !isSessionComplete {
            prefetchArtworkForUpcomingCards()
            if queue.count <= Self.prefetchThreshold && queue.count < remainingInSession {
                fetchNextPage()
            }
        }
        onQueueChange?()
    }

    func undoLastSwipe() {
        guard let last = lastSwipedCard else { return }
        lastSwipedCard = nil
        queue.insert(last.media, at: 0)
        sessionSwipeCount = max(0, sessionSwipeCount - 1)
        if last.direction == .like {
            sessionLikesCount = max(0, sessionLikesCount - 1)
        }
        sessionSwipedIDs.remove(last.media.id)
        excludedIDs.remove(last.media.id)
        tasteProfile.revertSessionSwipe(media: last.media, direction: last.direction)

        let previousTask = persistenceTask
        persistenceTask = Task { [weak self] in
            await previousTask?.value
            try? await self?.undoSwipeCardUseCase.execute(media: last.media, direction: last.direction)
        }
        onQueueChange?()
    }

    func startNewSessionBatch() {
        sessionSwipeCount = 0
        sessionLikesCount = 0
        lastSwipedCard = nil
        consecutiveEmptyPages = 0
        let remainingInSession = Self.sessionCardLimit
        if queue.count <= Self.prefetchThreshold && queue.count < remainingInSession {
            fetchNextPage()
        }
        prefetchArtworkForUpcomingCards()
        onQueueChange?()
    }

    private func prefetchArtworkForUpcomingCards() {
        guard let artworkPrefetcher else { return }
        for media in queue.prefix(5) {
            guard prefetchedArtworkIDs.insert(media.id).inserted else { continue }
            Task {
                await artworkPrefetcher.prefetchHeroArtwork(for: media)
            }
        }
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
                let result = try await self.fetchDeckUseCase.execute(
                    page: self.page,
                    excludingIDs: self.excludedIDs,
                    tasteProfile: self.tasteProfile
                )
                self.isFetching = false
                let existingQueueIDs = Set(self.queue.map(\.id))
                let freshItems = result.items.filter {
                    !self.excludedIDs.contains($0.id) && !existingQueueIDs.contains($0.id)
                }
                if freshItems.isEmpty {
                    self.consecutiveEmptyPages += 1
                } else {
                    self.consecutiveEmptyPages = 0
                    self.queue.append(contentsOf: freshItems)
                    self.prefetchArtworkForUpcomingCards()
                }
                self.isLastPage = result.isLastPage
                let nextPage = (result.isLastPage || self.page >= UserDefaultsSwipePaginationCursorStore.maxPage) ? UserDefaultsSwipePaginationCursorStore.defaultPage : (self.page + 1)
                self.page = nextPage
                self.paginationCursorStore.savePageCursor(nextPage)
                self.onQueueChange?()
                if self.queue.isEmpty && !self.isLastPage && self.consecutiveEmptyPages < Self.maxConsecutiveEmptyPages {
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
