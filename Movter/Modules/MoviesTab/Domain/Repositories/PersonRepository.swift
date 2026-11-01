//
//  ActorsRepository.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol PersonRepository: Sendable {
    func fetchPersonDetails(for personId: Int) async throws -> PersonDetails
    func fetchPersonCredits(for personId: Int) async throws -> [PersonCredit]
}
