//
//  RoleSelectionRepositoryImpl.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation
//import MentorNetwork

public final class RoleSelectionRepositoryImpl: RoleSelectionRepositoryProtocol {
    private let dataSource: RoleSelectionDataSourceProtocol

    public init(dataSource: RoleSelectionDataSourceProtocol) {
        self.dataSource = dataSource
    }

    public func submitRole(userType: String) async throws -> RoleSelectionResponseDTO {
        try await dataSource.submitRole(userType: userType)
    }
}
