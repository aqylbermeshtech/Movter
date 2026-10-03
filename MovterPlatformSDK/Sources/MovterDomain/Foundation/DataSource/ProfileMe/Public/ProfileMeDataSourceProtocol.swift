//
//  ProfileMeDataSourceProtocol.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorNetwork

nonisolated public protocol ProfileMeDataSourceProtocol {
    func getProfile() async throws -> ProfileMeResponseDTO
    func updatePersonal(_ request: UpdateProfilePersonalRequestDTO) async throws -> UpdateProfilePersonalOutcome
    func updatePhoto(_ request: UpdateProfilePhotoRequestDTO) async throws
    func updateMenteeProfile(_ request: UpdateMenteeProfileRequestDTO) async throws -> ProfileMeResponseDTO
    func confirmEmailChange(code: String) async throws
}
