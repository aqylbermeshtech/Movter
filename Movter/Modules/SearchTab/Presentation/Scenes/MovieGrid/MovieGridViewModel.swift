//
//  MovieGridViewModel.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

final class MovieGridViewModel {

    enum State: Equatable {
        case loading
        case results
        case message(String)
        case offline
    }

    var onChange: (() -> Void)?

    private let source: MediaQuerySource
    private let monitor: NetworkMonitoring
    private(set) var items: [Media] = []
    private(set) var state: State = .loading
    private(set) var didFail = false

    private var currentPage = 1
    private var isFetching = false
    private var hasMorePages = true

    private let searchMoviesUseCase: SearchMoviesUseCase
    private let fetchDiscoverUseCase: FetchDiscoverQueryUseCase

    init(
        source: MediaQuerySource,
        searchMoviesUseCase: SearchMoviesUseCase = DefaultSearchMoviesUseCase(),
        fetchDiscoverUseCase: FetchDiscoverQueryUseCase = DefaultFetchDiscoverQueryUseCase(),
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.source = source
        self.searchMoviesUseCase = searchMoviesUseCase
        self.fetchDiscoverUseCase = fetchDiscoverUseCase
        self.monitor = monitor
    }

    // MARK: - Loading

    func start() {
        if case .unsupported = source {
            state = .message("This list isn’t available yet.\nIt needs curated data the app doesn’t have.")
            onChange?()
            return
        }
        guard monitor.isOnline else {
            state = .offline
            onChange?()
            return
        }
        state = .loading
        onChange?()
        loadNextPage()
    }

    func retry() {
        guard state == .offline || didFail else { return }
        didFail = false
        hasMorePages = true
        start()
    }

    func connectivityDidChange() {
        guard monitor.isOnline, state == .offline else { return }
        retry()
    }

    func loadNextPage() {
        guard !isFetching, hasMorePages else { return }
        guard monitor.isOnline else {
            if items.isEmpty {
                state = .offline
                onChange?()
            }
            return
        }
        isFetching = true
        let page = currentPage

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let mediaPage: MediaPage
                switch self.source {
                case let .discover(query):
                    mediaPage = try await self.fetchDiscoverUseCase.execute(query: query, page: page)
                case let .search(text):
                    mediaPage = try await self.searchMoviesUseCase.execute(query: text, page: page)
                case .unsupported:
                    await MainActor.run {
                        self.isFetching = false
                    }
                    return
                }

                await MainActor.run {
                    self.isFetching = false
                    self.apply(mediaPage)
                    self.onChange?()
                }
            } catch {
                await MainActor.run {
                    self.isFetching = false
                    self.apply(nil)
                    self.onChange?()
                }
            }
        }
    }

    private func apply(_ result: MediaPage?) {
        guard let result = result else {
            hasMorePages = false
            guard items.isEmpty else { return }
            didFail = true
            state = monitor.isOnline
                ? .message("Couldn’t load results.\nPlease try again.")
                : .offline
            return
        }

        items.append(contentsOf: result.items)
        hasMorePages = !result.isLastPage
        currentPage += 1
        state = items.isEmpty ? .message(noResultsText) : .results
    }

    // MARK: - Presentation

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
