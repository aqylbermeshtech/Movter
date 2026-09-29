//
//  DevicesEndPoint.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Foundation

public enum DevicesEndPoint {
    case registerPushToken(request: PushDeviceTokenRequestDTO)
}

extension DevicesEndPoint: EndPointType {

    public var baseURL: URL {
        NetworkConfiguration.notificationServiceBaseURL ?? NetworkConfiguration.shared.baseURL
    }

    public var path: String {
        switch self {
        case .registerPushToken:
            return "v1/devices/push-token"
        }
    }

    public var httpMethod: RequestMethod {
        .post
    }

    public var task: RequestTask {
        switch self {
        case .registerPushToken(let request):
            return .requestEncodable(requestModel: request)
        }
    }

    public var headers: RequestHeaders? {
        [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
}

public struct PushDeviceTokenRequestDTO: Encodable, Sendable {
    public let fcmToken: String
    public let platform: String

    public init(fcmToken: String, platform: String) {
        self.fcmToken = fcmToken
        self.platform = platform
    }

    enum CodingKeys: String, CodingKey {
        case fcmToken = "fcm_token"
        case platform
    }
}

