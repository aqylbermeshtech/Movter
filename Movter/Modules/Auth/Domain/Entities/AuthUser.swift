//
//  AuthUser.swift
//  Movter
//

import Foundation

struct AuthUser: Equatable, Sendable {
    let id: String
    let email: String
    let displayName: String?

    init(id: String, email: String, displayName: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
    }
}

