//
//  MovieGridViewModel.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

/// Where a grid of results comes from — a browse selection or a typed query.
enum MediaQuerySource {
    case discover(DiscoverQuery)
    case search(String)
    /// A browse row with no TMDB filter behind it, so the screen can say so plainly
    /// instead of listing the entire catalogue as if it were a curated result.
    case unsupported
}

/// Paging and result state for a grid of films, from either browse or search.
final class MovieGridViewModel {

    /// What the grid should be showing. `.message` covers "nothing matched", "the
    /// request failed", and "this browse row has no query behind it" — three causes the
    /// screen draws identically, with the copy carrying the difference.
    enum State: Equatable {
        case loading
        case results
        case message(String)
    }

    var onChange: (() -> Void)?

    private let source: MediaQuerySource
    private(set) var items: [Media] = []
    private(set) var state: State = .loading
    /// Separates a failed request from a genuinely empty one. The grid renders both the
    /// same way; this is here for anything that needs to tell them apart, like a retry.
    private(set) var didFail = false

    private var currentPage = 1
    private var isFetching = false
    private var hasMorePages = true

    init(source: MediaQuerySource) {
        self.source = source
    }

    // MARK: - Loading

    /// First load. Resolves straight to a message when there is no query to run.
    func start() {
        if case .unsupported = source {
            state = .message("This list isn’t available yet.\nIt needs curated data the app doesn’t have.")
            onChange?()
            return
        }
        state = .loading
        onChange?()
        loadNextPage()
    }

    /// Safe to call from every scroll event: it no-ops while a page is in flight, and
    /// once TMDB has run out of pages.
    func loadNextPage() {
        guard !isFetching, hasMorePages else { return }
        isFetching = true
        let page = currentPage

        let handler: @MainActor (MediaPage?) -> Void = { [weak self] result in
            guard let self = self else { return }
            self.isFetching = false
            self.apply(result)
            self.onChange?()
        }

        switch source {
        case let .discover(query):
            NetworkService.shared.fetchDiscover(query: query, page: page, completion: handler)
        case let .search(text):
            NetworkService.shared.searchMovies(query: text, page: page, completion: handler)
        case .unsupported:
            isFetching = false
        }
    }

    private func apply(_ result: MediaPage?) {
        guard let result = result else {
            // Only surface a failure if there's nothing on screen already; a failed
            // page 3 shouldn't wipe out the two pages the user is looking at.
            hasMorePages = false
            guard items.isEmpty else { return }
            didFail = true
            state = .message("Couldn’t load results.\nCheck your connection and try again.")
            return
        }

        items.append(contentsOf: result.items)
        hasMorePages = !result.isLastPage
        currentPage += 1
        state = items.isEmpty ? .message(noResultsText) : .results
    }

    // MARK: - Presentation

    /// Takes an index rather than an `IndexPath` so this stays free of UIKit — the
    /// view controller is the layer that knows what an index path is.
    func item(at index: Int) -> Media? {
        items[safe: index]
    }

    private var noResultsText: String {
        if case let .search(text) = source {
            return "No films match “\(text)”."
        }
        return "Nothing here yet."
    }
}
