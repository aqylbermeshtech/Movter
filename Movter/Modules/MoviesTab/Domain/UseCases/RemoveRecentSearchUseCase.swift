//
//  RemoveRecentSearchUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol RemoveRecentSearchUseCase {
    func execute(_ term: String)
}

final class DefaultRemoveRecentSearchUseCase: RemoveRecentSearchUseCase {
    private let repository: RecentSearchesRepository
    
    init(repository: RecentSearchesRepository = DefaultRecentSearchesRepository()) {
        self.repository = repository
    }
    
    func execute(_ term: String) {
        repository.removeRecentSearch(term)
    }
}
