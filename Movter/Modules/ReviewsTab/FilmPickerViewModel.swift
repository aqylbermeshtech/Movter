//
//  FilmPickerViewModel.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

enum FilmSelection {
    case catalogue(Media)
    case manual(title: String)
}

final class FilmPickerViewModel {

    var onChange: (() -> Void)?

    private(set) var results: [Media] = []
    private(set) var isSearching = false
    private(set) var query = ""

    private static let minimumQueryLength = 2
    private static let debounceInterval: TimeInterval = 0.35

    private let service: MediaFetching
    private let monitor: NetworkMonitoring

    init(
        service: MediaFetching = TMDBService.shared,
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.service = service
        self.monitor = monitor
    }

    func connectivityDidChange() {
        guard monitor.isOnline, !query.isEmpty else {
            onChange?()
            return
        }
        updateQuery(query)
    }

    private var pendingSearch: DispatchWorkItem?
    private var currentSearchToken = 0

    // MARK: - Searching

    func updateQuery(_ text: String?) {
        query = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        pendingSearch?.cancel()

        guard query.count >= Self.minimumQueryLength else {
            currentSearchToken += 1
            results = []
            isSearching = false
            onChange?()
            return
        }

        guard monitor.isOnline else {
            results = []
            isSearching = false
            onChange?()
            return
        }

        let pending = query
        let work = DispatchWorkItem { [weak self] in self?.search(pending) }
        pendingSearch = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.debounceInterval, execute: work)
    }

    private func search(_ query: String) {
        currentSearchToken += 1
        let token = currentSearchToken
        isSearching = true
        onChange?()

        service.searchMovies(query: query, page: 1) { [weak self] page in
            guard let self = self, token == self.currentSearchToken else { return }
            self.isSearching = false
            self.results = page?.items ?? []
            self.onChange?()
        }
    }

    // MARK: - Presentation

    var statusText: String? {
        if isSearching { return nil }
        if !monitor.isOnline { return "You're offline. Searching the catalogue needs a connection." }
        if query.isEmpty { return "Search for the film you want to log." }
        if query.count < Self.minimumQueryLength { return "Keep typing…" }
        if results.isEmpty { return "Nothing found for “\(query)”." }
        return nil
    }

    var showsManualRow: Bool { !query.isEmpty }

    var manualRowTitle: String { "Add “\(query)” manually" }

    var manualSelection: FilmSelection { .manual(title: query) }

    func result(at index: Int) -> Media? {
        results[safe: index]
    }
}
