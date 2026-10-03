//
//  SignInUseCase.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorNetwork

nonisolated public final class SignInUseCase: SignInUseCaseProtocol {
    private let repository: AuthRepositoryProtocol
    
    public init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(credentials: AuthCredentialsDTO) async throws -> Bool {
        return try await repository.signIn(credentials: credentials)
    }
}
