//
//  RemoteDevicesDataSource.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Foundation
//import MentorCore
//import MentorNetwork

public final class RemoteDevicesDataSource: DevicesRemoteDataSourceProtocol {

    private let networkService: NetworkServiceProtocol
    private let router = Router<DevicesEndPoint>()
    private let logger: LoggerProtocol

    public init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
        self.logger = DIContainer.shared.resolve(LoggerProtocol.self) ?? Logger()
    }

    public func registerPushToken(fcmToken: String, platform: String) async throws {
        logger.debug("Registering push token (platform=\(platform))")
        let body = PushDeviceTokenRequestDTO(fcmToken: fcmToken, platform: platform)
        let endpoint = DevicesEndPoint.registerPushToken(request: body)
        let urlRequest = try router.request(endpoint)
        let (_, response) = try await networkService.request(urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            switch http.statusCode {
            case 401:
                throw NetworkError.unauthorized
            case 403:
                throw NetworkError.forbidden
            case 404:
                throw NetworkError.notFound
            default:
                throw NetworkError.serverError(http.statusCode)
            }
        }
        // Response body (if any) is ignored — backend may return `{}` or structured JSON.
    }
}

