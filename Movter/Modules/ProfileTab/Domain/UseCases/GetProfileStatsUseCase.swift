//
//  GetProfileStatsUseCase.swift
//  Movter
//

import Foundation

protocol GetProfileStatsUseCase {
    func execute() async throws -> ProfileStats
}

final class DefaultGetProfileStatsUseCase: GetProfileStatsUseCase {
    private let repository: ProfileStatsRepository

    init(repository: ProfileStatsRepository) {
        self.repository = repository
    }

    func execute() async throws -> ProfileStats {
        try await repository.fetchStats()
    }
}
