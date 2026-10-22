//
//  UpdateProfileUseCase.swift
//  Movter
//
//  Created by Nurtore on 22.10.2026.
//

import Foundation

protocol UpdateProfileUseCase {
    func execute(name: String, avatarURL: URL?) async throws
}

final class DefaultUpdateProfileUseCase: UpdateProfileUseCase {
    private let repository: ProfileRepository
    
    init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    func execute(name: String, avatarURL: URL?) async throws {
        try await repository.updateProfile(name: name, avatarURL: avatarURL)
    }
}
