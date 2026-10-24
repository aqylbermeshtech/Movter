//
//  MovieDetailsRepository.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol MovieDetailsRepository {
    func fetchTrailerKey(for mediaId: Int, type: MediaType) async throws -> String?
    func fetchSimilar(for mediaId: Int, type: MediaType, limit: Int) async throws -> [Media]
    func fetchCredits(for mediaId: Int, type: MediaType) async throws -> MovieCredits
}
