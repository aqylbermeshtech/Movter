//
//  AnalyticsEndPoint.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

public enum AnalyticsEndPoint {
    case sendEvent(request: AnalyticsEventRequestDTO)
}

extension AnalyticsEndPoint: EndPointType {

    public var baseURL: URL {
        NetworkConfiguration.shared.baseURL
    }

    public var path: String {
        switch self {
        case .sendEvent:
            return "v1/analytics/events"
        }
    }

    public var httpMethod: RequestMethod {
        .post
    }

    public var task: RequestTask {
        switch self {
        case .sendEvent(let request):
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
