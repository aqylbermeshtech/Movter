//
//  AppleSignInUseCase.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

public final class AppleSignInUseCase: AppleSignInUseCaseProtocol {
    private let repository: AuthRepositoryProtocol

    public init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(idToken: String, name: String?) async throws -> SocialAuthResult {
        return try await repository.signInWithApple(idToken: idToken, name: name)
    }
}
