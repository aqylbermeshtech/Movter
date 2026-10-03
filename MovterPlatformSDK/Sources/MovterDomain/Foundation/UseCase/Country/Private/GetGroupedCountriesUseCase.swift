//
//  GetGroupedCountriesUseCase.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation
//import MentorNetwork

public final class GetGroupedCountriesUseCase: GetGroupedCountriesUseCaseProtocol {
    private let repository: CountryRepositoryProtocol
    
    public init(repository: CountryRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(searchQuery: String) -> [(String, [CountryDTO])] {
        return repository.getGroupedCountries(searchQuery: searchQuery)
    }
}

