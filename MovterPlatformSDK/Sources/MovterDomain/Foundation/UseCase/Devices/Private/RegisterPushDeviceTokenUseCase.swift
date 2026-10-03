//
//  RegisterPushDeviceTokenUseCase.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Foundation

public final class RegisterPushDeviceTokenUseCase: RegisterPushDeviceTokenUseCaseProtocol {

    private let dataSource: DevicesRemoteDataSourceProtocol

    public init(dataSource: DevicesRemoteDataSourceProtocol) {
        self.dataSource = dataSource
    }

    public func execute(fcmToken: String, platform: String) async throws {
        try await dataSource.registerPushToken(fcmToken: fcmToken, platform: platform)
    }
}
