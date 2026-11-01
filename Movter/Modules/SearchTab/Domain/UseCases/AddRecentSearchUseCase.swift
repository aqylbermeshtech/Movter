//
//  AddRecentSearchUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol AddRecentSearchUseCase {
    func execute(_ term: String)
}

final class DefaultAddRecentSearchUseCase: AddRecentSearchUseCase {
    private let repository: RecentSearchesRepository
    
    init(repository: RecentSearchesRepository = DefaultRecentSearchesRepository()) {
        self.repository = repository
    }
    
    func execute(_ term: String) {
        repository.addRecentSearch(term)
    }
}
