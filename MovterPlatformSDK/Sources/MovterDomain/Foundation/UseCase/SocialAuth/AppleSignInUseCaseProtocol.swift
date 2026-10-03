//
//  AppleSignInUseCaseProtocol.swift
//  Movter
//
//  Created by Nurtore on 01.10.2026.
//

import Foundation

nonisolated public protocol AppleSignInUseCaseProtocol {
    func execute(idToken: String, name: String?) async throws -> SocialAuthResult
}
