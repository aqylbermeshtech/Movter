//
//  LegalRepositoryImpl.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

nonisolated public final class LegalRepositoryImpl: LegalRepositoryProtocol {
    private let dataSource: LegalDataSourceProtocol
    
    public init(dataSource: LegalDataSourceProtocol) {
        self.dataSource = dataSource
    }
    
    public func getTermsURL(lang: String) async throws -> String {
        return try await dataSource.getTermsURL(lang: lang)
    }
}
