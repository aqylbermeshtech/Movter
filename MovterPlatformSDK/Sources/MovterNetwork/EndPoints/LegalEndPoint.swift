//
//  LegalEndPoint.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

public enum LegalEndPoint {
    case getTerms(lang: String)
}

extension LegalEndPoint: EndPointType {

    public var baseURL: URL {
        return NetworkConfiguration.shared.baseURL
    }

    public var path: String {
        switch self {
        case .getTerms:
            return "v1/legal/terms"
        }
    }

    public var httpMethod: RequestMethod {
        switch self {
        case .getTerms:
            return .get
        }
    }

    public var task: RequestTask {
        switch self {
        case let .getTerms(lang):
            return .requestParameters(
                bodyParameters: nil,
                bodyEncoding: .urlEncoding,
                urlParameters: ["lang": lang]
            )
        }
    }

    public var headers: RequestHeaders? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
}

