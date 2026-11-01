//
//  RecentSearchesLocalDataSource.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol RecentSearchesLocalDataSource: AnyObject {
    func loadRecentSearches() -> [String]
    func saveRecentSearches(_ searches: [String])
    func clearRecentSearches()
}

final class UserDefaultRecentSearchesDataSource: RecentSearchesLocalDataSource {
    private let defaults: UserDefaults
    private let storageKey: String
    
    init(defaults: UserDefaults = .standard, storageKey: String = "recent_searches") {
        self.defaults = defaults
        self.storageKey = storageKey
    }
    
    func loadRecentSearches() -> [String] {
        defaults.stringArray(forKey: storageKey) ?? []
    }
    
    func saveRecentSearches(_ searches: [String]) {
        defaults.set(searches, forKey: storageKey)
    }
    
    func clearRecentSearches() {
        defaults.removeObject(forKey: storageKey)
    }
}
