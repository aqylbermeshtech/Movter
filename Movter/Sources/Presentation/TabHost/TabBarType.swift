//
//  TabBarType.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

//import MentorUI

enum TabBarType: Int, CaseIterable {
    case main = 0
    case catalog = 1
    case personalities = 2
    case applications = 3
    case profile = 4

    var title: String {
        switch self {
        case .main: return LocalizedString.Tabbar.main
        case .catalog: return LocalizedString.Tabbar.catalog
        case .applications: return LocalizedString.Tabbar.applications
        case .personalities: return LocalizedString.Tabbar.personalities
        case .profile: return LocalizedString.Tabbar.profile
        }
    }

    var iconName: String {
        switch self {
        case .main: return ImageAsset.main.name
        case .catalog: return ImageAsset.catalog.name
        case .applications: return ImageAsset.applications.name
        case .personalities: return ImageAsset.personalities.name
        case .profile: return ImageAsset.profile.name
        }
    }

    func title(isMentor: Bool) -> String {
        if isMentor, self == .catalog { return LocalizedString.Tabbar.calendar }
        return title
    }

    func iconName(isMentor: Bool) -> String {
        if isMentor, self == .catalog { return ImageAsset.calendar2.name }
        return iconName
    }
}

