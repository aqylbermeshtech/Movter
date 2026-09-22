//
//  UserModel.swift
//  Movter
//
//  Created by Nurtore on 23.09.2026.
//

import Foundation
//import MovterUI

struct UserModel: Identifiable, Equatable {
    let id: String
    let name: String
    let avatarUrl: String?
    let userType: String?
    
    init(id: String, name: String, avatarUrl: String?, userType: String?) {
        self.id = id
        self.name = name
        self.avatarUrl = avatarUrl
        self.userType = userType
    }
    
    var resolvedRole: UserRole? {
        guard let userType else { return nil }
        return UserRole(rawValue: userType)
    }
    
    var avatarImageName: String {
        ImageAsset.avatarPlaceholderNotionType.name
    }
    
    static var mock: UserModel {
        UserModel(id: "1", name: "Vro", avatarUrl: nil, userType: nil)
    }
}
