//
//  FetchStubArtworkUseCase.swift
//  Movter
//

import Foundation

protocol FetchStubArtworkUseCase {
    func execute(for review: Review) async -> StubArtwork
}

final class DefaultFetchStubArtworkUseCase: FetchStubArtworkUseCase {
    private let repository: StubsRepository

    init(repository: StubsRepository = DefaultStubsRepository()) {
        self.repository = repository
    }

    func execute(for review: Review) async -> StubArtwork {
        await repository.fetchStubArtwork(for: review)
    }
}
