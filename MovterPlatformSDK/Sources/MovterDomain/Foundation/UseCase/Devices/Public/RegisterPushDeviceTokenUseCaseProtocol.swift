//
//  RegisterPushDeviceTokenUseCaseProtocol.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Foundation

public protocol RegisterPushDeviceTokenUseCaseProtocol {
    func execute(fcmToken: String, platform: String) async throws
}
