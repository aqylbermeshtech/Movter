//
//  GetProfileUseCase.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import Foundation

protocol GetProfileUseCase {
    func execute() async throws -> UserProfile
}

final class DefaultGetProfileUseCase: GetProfileUseCase {
    private let repository: ProfileRepository
    
    init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> UserProfile {
        try await repository.fetchProfile()
    }
}
