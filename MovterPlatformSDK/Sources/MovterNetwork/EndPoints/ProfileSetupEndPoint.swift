//
//  ProfileSetupEndPoint.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

public enum ProfileSetupEndPoint {
    case getStatus
    case selectRole(userType: String)
    case createPhotoPresignedURL(contentType: String)
    case submitProfile(ProfileSetupRequestDTO)
}

extension ProfileSetupEndPoint: EndPointType {

    public var baseURL: URL {
        NetworkConfiguration.shared.baseURL
    }

    public var path: String {
        switch self {
        case .getStatus:
            return "v1/profile-setup/status"
        case .selectRole:
            return "v1/profile-setup/role"
        case .createPhotoPresignedURL:
            return "v1/upload/presigned-url"
        case .submitProfile:
            return "v1/profile-setup/profile"
        }
    }

    public var httpMethod: RequestMethod {
        switch self {
        case .getStatus:
            return .get
        case .selectRole, .createPhotoPresignedURL, .submitProfile:
            return .post
        }
    }

    public var task: RequestTask {
        switch self {
        case .getStatus:
            return .request
        case .selectRole(let userType):
            return .requestEncodable(requestModel: RoleSelectionRequestDTO(userType: userType))
        case .createPhotoPresignedURL(let contentType):
            return .requestEncodable(
                requestModel: PhotoPresignedURLRequestDTO(contentType: contentType)
            )
        case .submitProfile(let request):
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

private struct PhotoPresignedURLRequestDTO: Codable {
    let contentType: String

    enum CodingKeys: String, CodingKey {
        case contentType = "content_type"
    }
}
