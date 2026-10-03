//
//  EmailChangeConfirmRequestDTO.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

nonisolated public struct EmailChangeConfirmRequestDTO: Codable {
    public let code: String

    public init(code: String) {
        self.code = code
    }
}

