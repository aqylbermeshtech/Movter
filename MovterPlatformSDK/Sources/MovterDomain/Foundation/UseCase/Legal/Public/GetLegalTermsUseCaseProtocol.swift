//
//  GetLegalTermsUseCaseProtocol.swift
//  Movter
//
//  Created by Nurtore on 01.10.2026.
//

import Foundation

nonisolated public protocol GetLegalTermsUseCaseProtocol {
    func execute() async throws -> String
}
