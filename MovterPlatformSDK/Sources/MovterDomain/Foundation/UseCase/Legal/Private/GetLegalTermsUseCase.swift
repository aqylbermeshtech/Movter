//
//  GetLegalTermsUseCase.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation
//import MentorCore

public final class GetLegalTermsUseCase: GetLegalTermsUseCaseProtocol {
    private let repository: LegalRepositoryProtocol
    private let languageProvider: AppLanguageProviderProtocol

    public init(
        repository: LegalRepositoryProtocol,
        languageProvider: AppLanguageProviderProtocol = AppLanguageProvider.shared
    ) {
        self.repository = repository
        self.languageProvider = languageProvider
    }

    public func execute() async throws -> String {
        try await repository.getTermsURL(lang: languageProvider.currentLanguageCode)
    }
}
