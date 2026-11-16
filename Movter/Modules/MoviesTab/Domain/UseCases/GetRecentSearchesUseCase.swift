//
//  GetRecentSearchesUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol GetRecentSearchesUseCase {
    func execute() -> [String]
}

final class DefaultGetRecentSearchesUseCase: GetRecentSearchesUseCase {
    private let repository: RecentSearchesRepository
    
    init(repository: RecentSearchesRepository = DefaultRecentSearchesRepository()) {
        self.repository = repository
    }
    
    func execute() -> [String] {
        repository.getRecentSearches()
    }
}
