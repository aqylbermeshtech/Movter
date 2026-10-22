//
//  ProfileStatsRepository.swift
//  Movter
//

import Foundation

protocol ProfileStatsRepository {
    func fetchStats() async throws -> ProfileStats
}
