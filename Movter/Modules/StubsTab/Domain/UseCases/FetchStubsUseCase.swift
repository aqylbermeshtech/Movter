//
//  FetchStubsUseCase.swift
//  Movter
//

import Foundation

protocol FetchStubsUseCase {
    func execute() async throws -> [Review]
}

final class DefaultFetchStubsUseCase: FetchStubsUseCase {
    private let repository: StubsRepository

    init(repository: StubsRepository = DefaultStubsRepository()) {
        self.repository = repository
    }

    func execute() async throws -> [Review] {
        try await repository.fetchStubs()
    }
}
