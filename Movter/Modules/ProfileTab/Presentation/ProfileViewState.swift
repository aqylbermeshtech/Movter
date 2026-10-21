//
//  ProfileViewState.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import Foundation

enum ProfileViewState: Equatable {
    case loading
    case loaded(UserProfile)
    case failed(String)
}

