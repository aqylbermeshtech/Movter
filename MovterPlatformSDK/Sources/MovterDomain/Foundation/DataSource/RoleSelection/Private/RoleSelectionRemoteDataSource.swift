//
//  RoleSelectionRemoteDataSource.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation
//import MentorCore
//import MentorNetwork

public final class RoleSelectionRemoteDataSource: RoleSelectionDataSourceProtocol {
    private let networkService: NetworkServiceProtocol
    private let router = Router<ProfileSetupEndPoint>()
    private let logger: LoggerProtocol

    public init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
        self.logger = DIContainer.shared.resolve(LoggerProtocol.self) ?? Logger()
    }

    public func submitRole(userType: String) async throws -> RoleSelectionResponseDTO {
        logger.debug("Submitting role: \(userType)")

        let endPoint = ProfileSetupEndPoint.selectRole(userType: userType)
        let urlRequest = try router.request(endPoint)

        let (data, response) = try await networkService.request(urlRequest)

        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)

        guard let result: RoleSelectionResponseDTO = try await context.process() else {
            throw NetworkError.decodingError
        }

        return result
    }
}

