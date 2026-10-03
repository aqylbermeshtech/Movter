//
//  DeleteAccountOutcome.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

nonisolated public enum DeleteAccountOutcome {
    case accountFullyRemoved
    case retainedRemainingPersona(tokens: SwitchRoleData)
}
