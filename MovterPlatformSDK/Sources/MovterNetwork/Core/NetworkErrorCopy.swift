//
//  NetworkErrorCopy.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Foundation

nonisolated enum NetworkErrorCopy {
    static var generic: String {
        localized("network_error.generic", fallback: "Что-то пошло не так. Попробуйте ещё раз")
    }

    static var noInternet: String {
        localized("network_error.no_internet", fallback: "Нет подключения к интернету. Проверьте связь и попробуйте снова")
    }

    static var server: String {
        localized("network_error.server", fallback: "Сервис временно недоступен. Попробуйте позже")
    }

    static var unauthorized: String {
        localized("network_error.unauthorized", fallback: "Сессия истекла. Войдите заново")
    }

    static var notFound: String {
        localized("network_error.not_found", fallback: "Данные не найдены")
    }

    static var timeout: String {
        localized("network_error.timeout", fallback: "Сервер долго не отвечает. Попробуйте ещё раз")
    }

    private static func localized(_ key: String, fallback: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", bundle: .main, value: fallback, comment: "")
    }
}
