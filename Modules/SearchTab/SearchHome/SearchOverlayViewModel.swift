//
//  SearchOverlayViewModel.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

/// Recents, trending titles, and the rules deciding which sections the search overlay
/// shows for a given query.
final class SearchOverlayViewModel {

    /// The list's sections, ordered as they appear. `nonisolated` because the project
    /// defaults types to `@MainActor`, and the diffable data source needs a `Sendable`
    /// (non-isolated) `Hashable` conformance for its identifier types.
    nonisolated enum Section: Hashable {
        /// The single "Search for …" row shown while typing.
        case query
        /// Recents as wrapping chips — the idle state.
        case chips
        /// Recents as plain rows — filtered to the current query while typing.
        case recentRows
        case trending
        /// Placeholder rows while the trending request is in flight.
        case skeleton
    }

    nonisolated enum Item: Hashable {
        case query(String)
        /// A recent term. Which section it lands in — `chips` or `recentRows` — decides
        /// how it's drawn; the two never coexist in one snapshot.
        case term(String)
        case trending(rank: Int, title: String)
        case skeleton(Int)
    }

    /// One section and its contents. The view controller turns a list of these into a
    /// snapshot; deciding what's in the list is this type's job.
    struct SectionPlan {
        let section: Section
        let items: [Item]
    }

    /// A typed query needs at least this many characters before it'll run — mirrors the
    /// guard the results screen applies.
    private static let minQueryLength = 2
    private static let trendingLimit = 10
    private static let skeletonRowCount = 6

    var onChange: (() -> Void)?

    private let store: RecentSearchesStoring

    /// Whitespace-trimmed, and the only copy of the query the screen should read.
    private(set) var query = ""
    private(set) var recents: [String]
    private(set) var trending: [String] = []
    private(set) var isLoadingTrending = true

    init(store: RecentSearchesStoring = RecentSearchesStoreFactory.makeStore()) {
        self.store = store
        self.recents = store.all()
    }

    // MARK: - Composition

    /// What the list should contain right now. Pure: no UIKit, no network, no storage —
    /// just the four pieces of state above turned into sections.
    var plan: [SectionPlan] {
        guard !query.isEmpty else { return idlePlan }
        return typingPlan
    }

    private var idlePlan: [SectionPlan] {
        var plan: [SectionPlan] = []
        if !recents.isEmpty {
            plan.append(SectionPlan(section: .chips, items: recents.map { .term($0) }))
        }
        if isLoadingTrending {
            plan.append(SectionPlan(
                section: .skeleton,
                items: (0..<Self.skeletonRowCount).map { .skeleton($0) }
            ))
        } else if !trending.isEmpty {
            plan.append(SectionPlan(
                section: .trending,
                items: trending.prefix(Self.trendingLimit).enumerated().map {
                    .trending(rank: $0.offset + 1, title: $0.element)
                }
            ))
        }
        return plan
    }

    private var typingPlan: [SectionPlan] {
        var plan: [SectionPlan] = []
        if query.count >= Self.minQueryLength {
            plan.append(SectionPlan(section: .query, items: [.query(query)]))
        }
        let matches = recents.filter { $0.range(of: query, options: .caseInsensitive) != nil }
        if !matches.isEmpty {
            plan.append(SectionPlan(section: .recentRows, items: matches.map { .term($0) }))
        }
        return plan
    }

    /// The placeholder shows only when there is genuinely nothing to draw — not while
    /// the trending request is still filling the skeleton rows.
    var showsEmptyPlaceholder: Bool {
        plan.isEmpty && !isLoadingTrending
    }

    // MARK: - Input

    func updateQuery(_ text: String?) {
        query = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        onChange?()
    }

    /// Accepts a term and records it, or returns nil when it's too short to run.
    /// Deliberately doesn't refresh `recents` — the screen is dismissing.
    func submit(_ term: String) -> String? {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minQueryLength else { return nil }
        store.add(trimmed)
        return trimmed
    }

    func removeRecent(_ term: String) {
        store.remove(term)
        recents = store.all()
        onChange?()
    }

    func clearRecents() {
        store.clear()
        recents = []
        onChange?()
    }

    // MARK: - Trending

    func loadTrending() {
        NetworkService.shared.fetchTrendingContent(type: .movies) { [weak self] result in
            guard let self = self else { return }
            self.isLoadingTrending = false
            guard case let .media(items) = result else {
                self.onChange?()
                return
            }
            // Titles only — this list feeds queries, not a poster grid. De-duped because
            // a franchise can chart several times on the same day.
            self.trending = items
                .compactMap { $0.title ?? $0.name }
                .reduce(into: [String]()) { unique, title in
                    if !unique.contains(title) { unique.append(title) }
                }
            self.onChange?()
        }
    }
}
