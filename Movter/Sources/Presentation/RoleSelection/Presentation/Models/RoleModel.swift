//
//  RoleModel.swift
//  Movter
//
//  Created by Nurtore on 23.09.2026.
//

import Foundation
//import MovterUI

enum UserRole: String, CaseIterable, Identifiable {
    case mentee
    case mentor
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .mentee:
            return LocalizedString.RoleSelection.Mentee.title
        case .mentor:
            return LocalizedString.RoleSelection.Mentor.title
        }
    }
    
    var subtitle: String {
        switch self {
        case .mentee:
            return LocalizedString.RoleSelection.Mentee.subtitle
        case .mentor:
            return LocalizedString.RoleSelection.Mentor.subtitle
        }
    }

    var benefits: [String] {
        switch self {
        case .mentee:
            return [
                LocalizedString.RoleSelection.Mentee.benefit1,
                LocalizedString.RoleSelection.Mentee.benefit2,
                LocalizedString.RoleSelection.Mentee.benefit3
            ]
        case .mentor:
            return [
                LocalizedString.RoleSelection.Mentor.benefit1,
                LocalizedString.RoleSelection.Mentor.benefit2
            ]
        }
    }

    var tagTitle: String {
        switch self {
        case .mentee:
            return LocalizedString.RoleSelection.Mentee.tag
        case .mentor:
            return LocalizedString.RoleSelection.Mentor.tag
        }
    }

    var imageName: String {
        switch self {
        case .mentee:
            return ImageAsset.role1.name
        case .mentor:
            return ImageAsset.role2.name
        }
    }
}
