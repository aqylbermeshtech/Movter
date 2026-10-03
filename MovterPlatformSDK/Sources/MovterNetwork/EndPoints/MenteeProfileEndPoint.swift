//
//  MenteeProfileEndPoint.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

public enum MenteeProfileEndPoint {
    case updateProfile(UpdateMenteeProfileRequestDTO)
}

extension MenteeProfileEndPoint: EndPointType {
    public var baseURL: URL {
        NetworkConfiguration.shared.baseURL
    }

    public var path: String {
        switch self {
        case .updateProfile:
            return "v1/mentee/profile"
        }
    }

    public var httpMethod: RequestMethod {
        switch self {
        case .updateProfile:
            return .patch
        }
    }

    public var task: RequestTask {
        switch self {
        case .updateProfile(let request):
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

