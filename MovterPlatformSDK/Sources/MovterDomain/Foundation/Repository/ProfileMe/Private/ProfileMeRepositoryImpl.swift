//
//  ProfileMeRepositoryImpl.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorNetwork

nonisolated public final class ProfileMeRepositoryImpl: ProfileMeRepositoryProtocol {
    private let dataSource: ProfileMeDataSourceProtocol

    public init(dataSource: ProfileMeDataSourceProtocol) {
        self.dataSource = dataSource
    }

    public func getProfile() async throws -> ProfileMeDataDTO? {
        do {
            let response = try await dataSource.getProfile()
            return response.data
        } catch {
            if Self.isNoProfileYetError(error) {
                return nil
            }
            throw error
        }
    }

    /// Backend returns 404 until the user finishes onboarding (`Profile not found. Please complete profile setup first.`).
    private static func isNoProfileYetError(_ error: Error) -> Bool {
        normalizeNetworkError(error).isNotFound
    }

    private static func normalizeNetworkError(_ error: Error) -> NetworkError {
        if let net = error as? NetworkError {
            if case .unknown(let inner) = net {
                return normalizeNetworkError(inner)
            }
            return net
        }
        return NetworkError.from(error)
    }

    public func updatePersonal(_ request: UpdateProfilePersonalRequestDTO) async throws -> UpdateProfilePersonalOutcome {
        try await dataSource.updatePersonal(request)
    }

    public func updatePhoto(_ request: UpdateProfilePhotoRequestDTO) async throws {
        try await dataSource.updatePhoto(request)
    }

    public func updateMenteeProfile(_ request: UpdateMenteeProfileRequestDTO) async throws -> ProfileMeDataDTO? {
        let response = try await dataSource.updateMenteeProfile(request)
        return response.data
    }

    public func confirmEmailChange(code: String) async throws {
        try await dataSource.confirmEmailChange(code: code)
    }
}
