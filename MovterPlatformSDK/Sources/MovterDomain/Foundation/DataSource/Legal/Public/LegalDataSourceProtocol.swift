//
//  LegalDataSourceProtocol.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

nonisolated public protocol LegalDataSourceProtocol {
    func getTermsURL(lang: String) async throws -> String
}
