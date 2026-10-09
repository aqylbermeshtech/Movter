//
//  ProfileMeRepositoryProtocol.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

public protocol ProfileMeRepositoryProtocol {
    func getProfile() async throws -> ProfileMeDataDTO?
    func updatePersonal(_ request: UpdateProfilePersonalRequestDTO) async throws -> UpdateProfilePersonalOutcome
    func updatePhoto(_ request: UpdateProfilePhotoRequestDTO) async throws
    func confirmEmailChange(code: String) async throws
}
