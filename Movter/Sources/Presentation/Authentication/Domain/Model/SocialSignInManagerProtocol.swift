//
//  SocialSignInManagerProtocol.swift
//  Movter
//
//  Created by Nurtore on 01.10.2026.
//

import Foundation

protocol GoogleSignInManagerProtocol: AnyObject {
    @MainActor
    func signIn() async throws -> String
}

protocol AppleSignInManagerProtocol: AnyObject {
    @MainActor
    func signIn() async throws -> AppleSignInCredential
}

struct AppleSignInCredential {
    let idToken: String
    let name: String?
}

enum SocialAuthError: LocalizedError {
    case missingToken
    case noPresenter
    case googleSDKNotConfigured
    case cancelled

    var errorDescription: String? {
        switch self {
        case .missingToken: return "Не удалось получить токен"
        case .noPresenter: return "Нет контекста для отображения"
        case .googleSDKNotConfigured: return "Google Sign-In SDK не добавлен в проект"
        case .cancelled: return "Вход отменён"
        }
    }
}
