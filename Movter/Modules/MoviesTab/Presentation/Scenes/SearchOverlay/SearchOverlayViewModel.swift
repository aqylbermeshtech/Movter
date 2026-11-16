//
//  SearchOverlayViewModel.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

final class SearchOverlayViewModel {

    enum Section: Hashable {
        case query
        case chips
        case recentRows
        case trending
        case skeleton
    }

    enum Item: Hashable {
        case query(String)
        case term(String)
        case trending(rank: Int, title: String)
        case skeleton(Int)
    }

    struct SectionPlan {
        let section: Section
        let items: [Item]
    }

    private static let minQueryLength = 2
    private static let trendingLimit = 10
    private static let skeletonRowCount = 6

    var onChange: (() -> Void)?

    private let getRecentSearchesUseCase: GetRecentSearchesUseCase
    private let addRecentSearchUseCase: AddRecentSearchUseCase
    private let removeRecentSearchUseCase: RemoveRecentSearchUseCase
    private let clearRecentSearchesUseCase: ClearRecentSearchesUseCase
    private let fetchTrendingTitlesUseCase: FetchTrendingTitlesUseCase
    private let monitor: NetworkMonitoring

    private(set) var query = ""
    private(set) var recents: [String]
    private(set) var trending: [String] = []
    private(set) var isLoadingTrending = true

    init(
        getRecentSearchesUseCase: GetRecentSearchesUseCase = DefaultGetRecentSearchesUseCase(),
        addRecentSearchUseCase: AddRecentSearchUseCase = DefaultAddRecentSearchUseCase(),
        removeRecentSearchUseCase: RemoveRecentSearchUseCase = DefaultRemoveRecentSearchUseCase(),
        clearRecentSearchesUseCase: ClearRecentSearchesUseCase = DefaultClearRecentSearchesUseCase(),
        fetchTrendingTitlesUseCase: FetchTrendingTitlesUseCase = DefaultFetchTrendingTitlesUseCase(),
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.getRecentSearchesUseCase = getRecentSearchesUseCase
        self.addRecentSearchUseCase = addRecentSearchUseCase
        self.removeRecentSearchUseCase = removeRecentSearchUseCase
        self.clearRecentSearchesUseCase = clearRecentSearchesUseCase
        self.fetchTrendingTitlesUseCase = fetchTrendingTitlesUseCase
        self.monitor = monitor
        self.recents = getRecentSearchesUseCase.execute()
    }

    var emptyPlaceholderText: String {
        monitor.isOnline
            ? "Search for films by title"
            : "You're offline. Trending returns with your connection."
    }

    func connectivityDidChange() {
        if monitor.isOnline, trending.isEmpty {
            isLoadingTrending = true
            loadTrending()
        } else {
            onChange?()
        }
    }

    // MARK: - Composition

    var plan: [SectionPlan] {
        guard !query.isEmpty else { return idlePlan }
        return typingPlan
    }

    private var idlePlan: [SectionPlan] {
        var plan: [SectionPlan] = []
        if !recents.isEmpty {
            plan.append(SectionPlan(section: .chips, items: recents.map { .term($0) }))
        }
        if !monitor.isOnline {
            return plan
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

    var showsEmptyPlaceholder: Bool {
        plan.isEmpty && !isLoadingTrending
    }

    // MARK: - Input

    func updateQuery(_ text: String?) {
        query = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        onChange?()
    }

    func submit(_ term: String) -> String? {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minQueryLength else { return nil }
        addRecentSearchUseCase.execute(trimmed)
        return trimmed
    }

    func removeRecent(_ term: String) {
        removeRecentSearchUseCase.execute(term)
        recents = getRecentSearchesUseCase.execute()
        onChange?()
    }

    func clearRecents() {
        clearRecentSearchesUseCase.execute()
        recents = []
        onChange?()
    }

    // MARK: - Trending

    func loadTrending() {
        guard monitor.isOnline else {
            isLoadingTrending = false
            onChange?()
            return
        }
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let titles = try await self.fetchTrendingTitlesUseCase.execute(limit: Self.trendingLimit)
                await MainActor.run {
                    self.isLoadingTrending = false
                    self.trending = titles
                    self.onChange?()
                }
            } catch {
                await MainActor.run {
                    self.isLoadingTrending = false
                    self.onChange?()
                }
            }
        }
    }
}
