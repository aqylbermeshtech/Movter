//
//  DefaultRecentSearchesRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

final class DefaultRecentSearchesRepository: RecentSearchesRepository {

    private let localDataSource: RecentSearchesLocalDataSource
    private let limit: Int

    init(
        localDataSource: RecentSearchesLocalDataSource = UserDefaultRecentSearchesDataSource(),
        limit: Int = 8
    ) {
        self.localDataSource = localDataSource
        self.limit = limit
    }

    func getRecentSearches() -> [String] {
        localDataSource.loadRecentSearches()
    }

    func addRecentSearch(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var items = getRecentSearches().filter {
            $0.caseInsensitiveCompare(trimmed) != .orderedSame
        }
        items.insert(trimmed, at: 0)
        localDataSource.saveRecentSearches(Array(items.prefix(limit)))
    }

    func removeRecentSearch(_ term: String) {
        let items = getRecentSearches().filter { $0 != term }
        localDataSource.saveRecentSearches(items)
    }

    func clearRecentSearches() {
        localDataSource.clearRecentSearches()
    }
}

