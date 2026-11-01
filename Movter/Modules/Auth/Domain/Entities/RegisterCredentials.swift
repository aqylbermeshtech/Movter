//
//  RegisterCredentials.swift
//  Movter
//

import Foundation

struct RegisterCredentials: Equatable {
    let username: String
    let email: String
    let password: String

    init(username: String, email: String, password: String) {
        self.username = username
        self.email = email
        self.password = password
    }
}

