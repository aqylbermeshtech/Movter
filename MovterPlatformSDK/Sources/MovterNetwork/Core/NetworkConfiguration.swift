//
//  NetworkConfiguration.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Foundation

nonisolated public protocol NetworkConfigurationProtocol {
    var baseURL: URL { get }
    var timeout: TimeInterval { get }
}

nonisolated public final class NetworkConfiguration: NetworkConfigurationProtocol {
    nonisolated(unsafe) public static var shared: NetworkConfigurationProtocol = NetworkConfiguration()

    nonisolated(unsafe) public private(set) static var notificationServiceBaseURL: URL?

    public var baseURL: URL
    public var timeout: TimeInterval

    public init(
        baseURL: URL = URL(string: "https://www.platform-mentor.com/api")!,
        timeout: TimeInterval = 30.0
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
    }

    public static func configure(
        baseURL: URL,
        notificationServiceBaseURL: URL? = nil,
        timeout: TimeInterval = 30.0
    ) {
        shared = NetworkConfiguration(baseURL: baseURL, timeout: timeout)
        Self.notificationServiceBaseURL = notificationServiceBaseURL
    }
}
