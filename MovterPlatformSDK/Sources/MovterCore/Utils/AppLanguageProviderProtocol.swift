//
//  AppLanguageProviderProtocol.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

public protocol AppLanguageProviderProtocol {
    var currentLanguageCode: String { get }
}

public final class AppLanguageProvider: AppLanguageProviderProtocol {
    public static var shared: AppLanguageProviderProtocol = AppLanguageProvider()

    public let supportedLanguageCodes: Set<String>
    public let fallbackLanguageCode: String

    public init(
        supportedLanguageCodes: Set<String> = ["en", "ru"],
        fallbackLanguageCode: String = "en"
    ) {
        self.supportedLanguageCodes = supportedLanguageCodes
        self.fallbackLanguageCode = fallbackLanguageCode
    }

    public var currentLanguageCode: String {
        let rawCode = Bundle.main.preferredLocalizations.first
            .flatMap { Locale(identifier: $0).language.languageCode?.identifier }
            ?? fallbackLanguageCode
        return supportedLanguageCodes.contains(rawCode) ? rawCode : fallbackLanguageCode
    }

    public static func configure(
        supportedLanguageCodes: Set<String>,
        fallbackLanguageCode: String
    ) {
        shared = AppLanguageProvider(
            supportedLanguageCodes: supportedLanguageCodes,
            fallbackLanguageCode: fallbackLanguageCode
        )
    }
}
