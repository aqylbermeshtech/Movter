//
//  RoleSelectionViewManager.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation
import SwiftUI
import Combine

protocol RoleSelectionViewManagerDelegate: AnyObject {
    func onSelectRole(_ role: UserRole)
    func onContinue()
}

final class RoleSelectionViewManager: ObservableObject {
    weak var delegate: RoleSelectionViewManagerDelegate?

    @Published var selectedRole: UserRole?

    var canContinue: Bool {
        selectedRole != nil
    }

    func setSelectedRole(_ role: UserRole?) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedRole = role
        }
    }

    func selectRole(_ role: UserRole) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedRole = role
        }
    }
}

