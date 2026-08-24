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

    /// Below this many queued cards, the next page is already on its way.
    private static let prefetchThreshold = 3
    /// One round is 10 swipes; the deck stops offering cards past that until the
    /// view controller is torn down and rebuilt (a fresh app launch).
    static let sessionCardLimit = 10

    private let watchlistStore: WatchlistStoring
    private let seenFilmsStore: SeenFilmsStoring
    private var queue: [Media] = []
    private var page = 1
    private var isFetching = false
    private var isLastPage = false
    /// tmdbIDs never to show — seeded from `seenFilmsStore` on `start()`, then grown
    /// as the user swipes (either direction) this session.
    private var excludedIDs: Set<Int> = []

    private(set) var sessionSwipeCount = 0
    var isSessionComplete: Bool { sessionSwipeCount >= Self.sessionCardLimit }

    /// Fires whenever the queue changes — a page landed, or a card was consumed.
    var onQueueChange: (() -> Void)?
    var onError: ((String) -> Void)?

    init(watchlistStore: WatchlistStoring, seenFilmsStore: SeenFilmsStoring) {
        self.watchlistStore = watchlistStore
        self.seenFilmsStore = seenFilmsStore
    }

    var isExhausted: Bool { queue.isEmpty && isLastPage && !isFetching }

    /// Up to `count` cards without consuming them, front of the deck first — capped
    /// to however many swipes are left in the session, so the deck never hands out a
    /// card past the limit even if more are already queued.
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

    /// Call once a card has finished animating off-screen.
    func consumeFrontCard(direction: SwipeDirection) {
        guard !queue.isEmpty, !isSessionComplete else { return }
        let media = queue.removeFirst()
        sessionSwipeCount += 1
        // Marked seen regardless of direction: a pass shouldn't be able to resurface
        // any more than a like should.
        excludedIDs.insert(media.id)
        seenFilmsStore.markSeen(media.id)
        if direction == .like {
            watchlistStore.save(WatchlistItem(from: media)) { _ in
                // A failed save just means the film silently isn't on the list;
                // nothing on this screen depends on knowing that happened.
            }
        }
        if !isSessionComplete && queue.count <= Self.prefetchThreshold {
            fetchNextPage()
        }
        onQueueChange?()
    }

    private func fetchNextPage() {
        guard !isFetching, !isLastPage, !isSessionComplete else { return }
        isFetching = true
        NetworkService.shared.fetchPopularMovies(page: page) { [weak self] result in
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
            // A whole page can filter down to nothing (e.g. it's mostly already on
            // the watchlist) with no card on screen to trigger the next fetch via a
            // swipe, so keep pulling pages until something survives or we run out.
            if self.queue.isEmpty && !self.isLastPage {
                self.fetchNextPage()
            }
        }
    }
}
