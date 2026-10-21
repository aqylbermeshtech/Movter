//
//  ProfileRepository.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import Foundation

protocol ProfileRepository {
    func fetchProfile() async throws -> UserProfile
}
