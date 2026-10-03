//
//  ProfileMeRepositoryProtocol.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorNetwork

nonisolated public protocol ProfileMeRepositoryProtocol {
    func getProfile() async throws -> ProfileMeDataDTO?
    func updatePersonal(_ request: UpdateProfilePersonalRequestDTO) async throws -> UpdateProfilePersonalOutcome
    func updatePhoto(_ request: UpdateProfilePhotoRequestDTO) async throws
    func updateMenteeProfile(_ request: UpdateMenteeProfileRequestDTO) async throws -> ProfileMeDataDTO?
    func confirmEmailChange(code: String) async throws
}
