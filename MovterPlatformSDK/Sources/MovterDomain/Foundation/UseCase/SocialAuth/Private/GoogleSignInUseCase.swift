//
//  GoogleSignInUseCase.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

nonisolated public final class GoogleSignInUseCase: GoogleSignInUseCaseProtocol {
    private let repository: AuthRepositoryProtocol

    public init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(idToken: String) async throws -> SocialAuthResult {
        return try await repository.signInWithGoogle(idToken: idToken)
    }
}
