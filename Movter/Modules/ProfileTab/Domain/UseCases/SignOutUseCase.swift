//
//  SignOutUseCase.swift
//  Movter
//
//  Created by Nurtore on 22.10.2026.
//

import Foundation

protocol SignOutUseCase {
    func execute() async throws
}

final class DefaultSignOutUseCase: SignOutUseCase {
    private let repository: ProfileRepository
    
    init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    func execute() async throws {
        try repository.signOut()
    }
}
