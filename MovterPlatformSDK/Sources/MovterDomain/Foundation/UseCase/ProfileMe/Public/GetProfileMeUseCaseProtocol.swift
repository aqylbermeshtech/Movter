//
//  GetProfileMeUseCaseProtocol.swift
//  Movter
//
//  Created by Nurtore on 25.09.2026.
//

import Foundation
//import MovterNetwork

public protocol GetProfileMeUseCaseProtocol {
    func execute() async throws -> ProfileMeDataDTO?
}
