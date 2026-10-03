//
//  ProfileMeRemoteDataSource.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorCore
//import MentorNetwork

public final class ProfileMeRemoteDataSource: ProfileMeDataSourceProtocol {
    private let networkService: NetworkServiceProtocol
    private let router = Router<ProfileEndPoint>()
    private let menteeProfileRouter = Router<MenteeProfileEndPoint>()
    private let logger: LoggerProtocol

    public init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
        self.logger = DIContainer.shared.resolve(LoggerProtocol.self) ?? Logger()
    }

    public func getProfile() async throws -> ProfileMeResponseDTO {
        let endPoint = ProfileEndPoint.getMe
        let urlRequest = try router.request(endPoint)

        let (data, response) = try await networkService.request(urlRequest)

        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)

        guard let result: ProfileMeResponseDTO = try await context.process() else {
            throw NetworkError.decodingError
        }

        return result
    }

    public func updatePersonal(_ request: UpdateProfilePersonalRequestDTO) async throws -> UpdateProfilePersonalOutcome {
        let endPoint = ProfileEndPoint.updatePersonal(request)
        let urlRequest = try router.request(endPoint)
        let (data, response) = try await networkService.request(urlRequest)

        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)

        guard let parsed: UpdateProfilePersonalResponseDTO = try await context.process() else {
            throw NetworkError.decodingError
        }
        guard parsed.success else {
            let text = parsed.error ?? parsed.message ?? ""
            throw NetworkError.unknown(
                NSError(
                    domain: "UpdateProfilePersonal",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: text.isEmpty ? "Request failed" : text]
                )
            )
        }
        guard let profile = parsed.data?.profile else {
            throw NetworkError.decodingError
        }
        return UpdateProfilePersonalOutcome(
            profile: profile,
            maskedNewEmail: parsed.data?.maskedNewEmail,
            emailVerificationRequired: parsed.data?.emailVerificationRequired
        )
    }

    public func updatePhoto(_ request: UpdateProfilePhotoRequestDTO) async throws {
        let endPoint = ProfileEndPoint.updatePhoto(request)
        let urlRequest = try router.request(endPoint)
        let (data, response) = try await networkService.request(urlRequest)

        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)

        guard let parsed: UpdateProfilePhotoResponseDTO = try await context.process() else {
            throw NetworkError.decodingError
        }

        guard parsed.success else {
            let text = parsed.error ?? parsed.message ?? ""
            throw NetworkError.unknown(
                NSError(
                    domain: "UpdateProfilePhoto",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: text.isEmpty ? "Request failed" : text]
                )
            )
        }
    }

    public func updateMenteeProfile(_ request: UpdateMenteeProfileRequestDTO) async throws -> ProfileMeResponseDTO {
        let endPoint = MenteeProfileEndPoint.updateProfile(request)
        let urlRequest = try menteeProfileRouter.request(endPoint)
        let (data, response) = try await networkService.request(urlRequest)
        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)

        guard let parsed: ProfileMeResponseDTO = try await context.process() else {
            throw NetworkError.decodingError
        }
        guard parsed.success else {
            let text = parsed.error ?? parsed.message ?? ""
            throw NetworkError.unknown(
                NSError(
                    domain: "UpdateMenteeProfile",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: text.isEmpty ? "Request failed" : text]
                )
            )
        }
        return parsed
    }

    public func confirmEmailChange(code: String) async throws {
        let request = EmailChangeConfirmRequestDTO(code: code)
        let endPoint = ProfileEndPoint.confirmEmailChange(request)
        let urlRequest = try router.request(endPoint)
        let (data, response) = try await networkService.request(urlRequest)

        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)

        guard let parsed: EmailChangeConfirmResponseDTO = try await context.process() else {
            throw NetworkError.decodingError
        }
        guard parsed.success else {
            let text = parsed.error ?? parsed.message ?? ""
            throw NetworkError.unknown(
                NSError(
                    domain: "ConfirmEmailChange",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: text.isEmpty ? "Request failed" : text]
                )
            )
        }
    }
}

