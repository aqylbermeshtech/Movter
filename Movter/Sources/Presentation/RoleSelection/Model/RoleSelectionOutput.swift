//
//  RoleSelectionOutput.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

struct RoleSelectionOutput {
    let onRoleSelected: (UserRole) -> Void
    let onBack: () -> Void
}
