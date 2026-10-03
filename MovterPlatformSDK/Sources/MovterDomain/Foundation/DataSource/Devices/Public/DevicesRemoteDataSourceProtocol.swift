//
//  DevicesRemoteDataSourceProtocol.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Foundation

public protocol DevicesRemoteDataSourceProtocol {
    func registerPushToken(fcmToken: String, platform: String) async throws
}
