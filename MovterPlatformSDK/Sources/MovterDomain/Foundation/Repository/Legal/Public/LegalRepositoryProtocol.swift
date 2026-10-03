//
//  LegalRepositoryProtocol.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

public protocol LegalRepositoryProtocol {
    func getTermsURL(lang: String) async throws -> String
}
