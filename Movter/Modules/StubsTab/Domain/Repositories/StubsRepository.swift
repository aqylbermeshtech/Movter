//
//  StubsRepository.swift
//  Movter
//

import Foundation

protocol StubsRepository {
    func fetchStubs() async throws -> [Review]
    func fetchStubArtwork(for review: Review) async -> StubArtwork
}
