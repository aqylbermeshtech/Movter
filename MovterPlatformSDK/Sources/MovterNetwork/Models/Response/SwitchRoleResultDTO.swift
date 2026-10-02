//
//  SwitchRoleResultDTO.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

public struct SwitchRoleResultDTO: Sendable {
    public let activeRole: String

    public init(activeRole: String) {
        self.activeRole = activeRole
    }
}
