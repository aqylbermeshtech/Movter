//
//  GetCountryByIdUseCase.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorNetwork

public final class GetCountryByIdUseCase: GetCountryByIdUseCaseProtocol {
    private let repository: CountryRepositoryProtocol
    
    public init(repository: CountryRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(id: String) -> CountryDTO? {
        return repository.getCountryById(id: id)
    }
}

