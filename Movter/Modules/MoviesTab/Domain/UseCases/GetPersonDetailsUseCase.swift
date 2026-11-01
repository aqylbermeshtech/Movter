//
//  GetPersonDetailsUseCase.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol GetPersonDetailsUseCase {
    func execute(for personId: Int) async throws -> PersonDetails
}

final class DefaultGetPersonDetailsUseCase: GetPersonDetailsUseCase {
    private let repository: PersonRepository
    
    init(repository: PersonRepository = DefaultPersonRepository()) {
        self.repository = repository
    }
    
    func execute(for personId: Int) async throws -> PersonDetails {
        try await repository.fetchPersonDetails(for: personId)
    }
}
