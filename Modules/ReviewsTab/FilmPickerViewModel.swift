//
//  FilmPickerViewModel.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

/// A catalogue title, or a name typed by hand.
enum FilmSelection {
    case catalogue(Media)
    case manual(title: String)
}

/// Debounced catalogue search for the film being reviewed.
final class FilmPickerViewModel {

    var onChange: (() -> Void)?

    private(set) var results: [Media] = []
    private(set) var isSearching = false
    /// Whitespace-trimmed, and the only copy of the query the screen should read.
    private(set) var query = ""

    /// Below this, a search would match most of the catalogue and isn't worth a request.
    private static let minimumQueryLength = 2
    private static let debounceInterval: TimeInterval = 0.35

    private let service: MediaFetching

    init(service: MediaFetching = NetworkService.shared) {
        self.service = service
    }

    private var pendingSearch: DispatchWorkItem?
    /// Bumped per keystroke so a slow response can't overwrite a newer one.
    private var currentSearchToken = 0

    // MARK: - Searching

    func updateQuery(_ text: String?) {
        query = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        pendingSearch?.cancel()

        guard query.count >= Self.minimumQueryLength else {
            // Bumping the token here too, so a request already in flight can't land and
            // repopulate a list the user has just cleared.
            currentSearchToken += 1
            results = []
            isSearching = false
            onChange?()
            return
        }

        // Debounced: one request per keystroke would burn the API budget.
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

    /// Nil while a search is running or results are on screen — the list speaks for
    /// itself in both cases.
    var statusText: String? {
        if isSearching { return nil }
        if query.isEmpty { return "Search for the film you want to log." }
        if query.count < Self.minimumQueryLength { return "Keep typing…" }
        if results.isEmpty { return "Nothing found for “\(query)”." }
        return nil
    }

    /// The hand-typed fallback appears as soon as there's a name to add.
    var showsManualRow: Bool { !query.isEmpty }

    var manualRowTitle: String { "Add “\(query)” manually" }

    var manualSelection: FilmSelection { .manual(title: query) }

    /// Takes an index rather than an `IndexPath` so this stays free of UIKit.
    func result(at index: Int) -> Media? {
        results[safe: index]
    }
}
