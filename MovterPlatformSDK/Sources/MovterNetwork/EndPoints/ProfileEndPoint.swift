//
//  ProfileEndPoint.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

nonisolated public enum ProfileEndPoint {
    case getMe
    case updatePersonal(UpdateProfilePersonalRequestDTO)
    case updatePhoto(UpdateProfilePhotoRequestDTO)
    case confirmEmailChange(EmailChangeConfirmRequestDTO)
}

extension ProfileEndPoint: EndPointType {

    public var baseURL: URL {
        NetworkConfiguration.shared.baseURL
    }

    public var path: String {
        switch self {
        case .getMe:
            return "v1/profiles/me"
        case .updatePersonal:
            return "v1/profiles/me/personal"
        case .updatePhoto:
            return "v1/profiles/me/photo"
        case .confirmEmailChange:
            return "v1/profiles/me/email-change/confirm"
        }
    }

    public var httpMethod: RequestMethod {
        switch self {
        case .getMe:
            return .get
        case .updatePersonal:
            return .patch
        case .updatePhoto:
            return .patch
        case .confirmEmailChange:
            return .post
        }
    }

    public var task: RequestTask {
        switch self {
        case .getMe:
            return .request
        case .updatePersonal(let body):
            return .requestEncodable(requestModel: body)
        case .updatePhoto(let body):
            return .requestEncodable(requestModel: body)
        case .confirmEmailChange(let body):
            return .requestEncodable(requestModel: body)
        }
    }

    public var headers: RequestHeaders? {
        [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
}
