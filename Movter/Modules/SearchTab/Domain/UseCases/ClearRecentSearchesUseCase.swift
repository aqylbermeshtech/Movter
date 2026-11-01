//
//  ClearRecentSearchesUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol ClearRecentSearchesUseCase {
    func execute()
}

final class DefaultClearRecentSearchesUseCase: ClearRecentSearchesUseCase {
    private let repository: RecentSearchesRepository
    
    init(repository: RecentSearchesRepository = DefaultRecentSearchesRepository()) {
        self.repository = repository
    }
    
    func execute() {
        repository.clearRecentSearches()
    }
}
