//
//  DefaultPersonRepository.swift
//  Movter
//

import Foundation

final class DefaultPersonRepository: PersonRepository, @unchecked Sendable {
    private let remoteDataSource: MoviesRemoteDataSource

    init(remoteDataSource: MoviesRemoteDataSource = TMDBMoviesRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchPersonDetails(for personId: Int) async throws -> PersonDetails {
        try await remoteDataSource.fetchPersonDetails(for: personId)
    }

    func fetchPersonCredits(for personId: Int) async throws -> [PersonCredit] {
        let rawCredits = try await remoteDataSource.fetchPersonCredits(for: personId)
        var seen = Set<Int>()
        return rawCredits
            .sorted { $0.sortDate > $1.sortDate }
            .filter { seen.insert($0.id).inserted }
    }
}

