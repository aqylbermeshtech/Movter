//
//  SubmitRoleSelectionUseCase.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation
//import MentorNetwork

public final class SubmitRoleSelectionUseCase: SubmitRoleSelectionUseCaseProtocol {
    private let repository: RoleSelectionRepositoryProtocol

    public init(repository: RoleSelectionRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(userType: String) async throws -> RoleSelectionResponseDTO {
        try await repository.submitRole(userType: userType)
    }
}

