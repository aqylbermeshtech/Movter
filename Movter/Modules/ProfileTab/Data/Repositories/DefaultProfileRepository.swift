//
//  DefaultProfileRepository.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import Foundation

final class DefaultProfileRepository: ProfileRepository {

    private let dataSource: ProfileDataSource

    init(dataSource: ProfileDataSource) {
        self.dataSource = dataSource
    }

    func fetchProfile() async throws -> UserProfile {
        let dto = try await dataSource.fetchCurrentUser()
        return dto.toDomain()
    }
}

