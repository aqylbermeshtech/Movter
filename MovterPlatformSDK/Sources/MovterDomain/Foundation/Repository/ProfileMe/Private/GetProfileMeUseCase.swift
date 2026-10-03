//
//  GetProfileMeUseCase.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorNetwork

public final class GetProfileMeUseCase: GetProfileMeUseCaseProtocol {
    private let repository: ProfileMeRepositoryProtocol

    public init(repository: ProfileMeRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> ProfileMeDataDTO? {
        try await repository.getProfile()
    }
}
