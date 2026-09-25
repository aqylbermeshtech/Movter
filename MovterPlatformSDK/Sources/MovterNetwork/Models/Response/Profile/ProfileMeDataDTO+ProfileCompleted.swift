//
//  ProfileMeDataDTO+ProfileCompleted.swift
//  Movter
//
//  Created by Nurtore on 25.09.2026.
//

import Foundation

public extension ProfileMeDataDTO {
    var isProfileFullyCompleted: Bool {
        isSettingsCompleted == true
    }
}

