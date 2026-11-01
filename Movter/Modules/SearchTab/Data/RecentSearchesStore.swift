//
//  RecentSearchesStore.swift
//  Movter
//
//  Created by Nurtore on 27.08.2026.
//

import Foundation

protocol RecentSearchesStoring: AnyObject {
    func all() -> [String]
    func add(_ term: String)
    func remove(_ term: String)
    func clear()
}

enum RecentSearchesStoreFactory {
    static func makeStore() -> RecentSearchesStoring {
        LocalRecentSearchesStore()
    }
}

final class LocalRecentSearchesStore: RecentSearchesStoring {

    private let repository: RecentSearchesRepository

    init(repository: RecentSearchesRepository = DefaultRecentSearchesRepository()) {
        self.repository = repository
    }

    func all() -> [String] {
        repository.getRecentSearches()
    }

    func add(_ term: String) {
        repository.addRecentSearch(term)
    }

    func remove(_ term: String) {
        repository.removeRecentSearch(term)
    }

    func clear() {
        repository.clearRecentSearches()
    }
}
