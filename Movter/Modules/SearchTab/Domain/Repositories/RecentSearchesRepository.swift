//
//  RecentSearchesRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol RecentSearchesRepository {
    func getRecentSearches() -> [String]
    func addRecentSearch(_ term: String)
    func removeRecentSearch(_ term: String)
    func clearRecentSearches()
}
