//
//  AuthError.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

nonisolated public enum AuthError: Error, LocalizedError {
    case phoneNotSupported
    case invalidCredentials

    public var errorDescription: String? {
        switch self {
        case .phoneNotSupported:
            return "Вход по телефону пока не поддерживается"
        case .invalidCredentials:
            return "Неверные данные для входа"
        }
    }
}
