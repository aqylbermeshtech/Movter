//
//  GetPersonCreditsUseCase.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol GetPersonCreditsUseCase {
    func execute(for personId: Int) async throws -> [PersonCredit]
}

final class DefaultGetPersonCreditsUseCase: GetPersonCreditsUseCase {
    private let repository: PersonRepository
    
    init(repository: PersonRepository = DefaultPersonRepository()) {
        self.repository = repository
    }
    
    func execute(for personId: Int) async throws -> [PersonCredit] {
        try await repository.fetchPersonCredits(for: personId)
    }
}
