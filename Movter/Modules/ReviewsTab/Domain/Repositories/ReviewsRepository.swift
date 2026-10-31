//
//  ReviewsRepository.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol ReviewsRepository {
    func fetchAll() async throws -> [Review]
    func fetchReview(for mediaId: Int) async throws -> Review?
    func saveReview(_ review: Review) async throws
    func deleteReview(id: UUID) async throws
}
