//
//  RoleSelectionRepositoryProtocol.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation
//import MentorNetwork

public protocol RoleSelectionRepositoryProtocol {
    func submitRole(userType: String) async throws -> RoleSelectionResponseDTO
}
