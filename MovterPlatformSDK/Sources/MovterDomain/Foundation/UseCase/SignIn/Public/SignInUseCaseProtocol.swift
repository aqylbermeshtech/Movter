//
//  SignInUseCaseProtocol.swift
//  Movter
//
//  Created by Nurtore on 01.10.2026.
//

import Foundation
//import MeovterNetwork

public protocol SignInUseCaseProtocol {
    func execute(credentials: AuthCredentialsDTO) async throws -> Bool
}

