//
//  AuthCredentials.swift
//  Movter
//
//  Created by Nurtore on 01.10.2026.
//

import Foundation
//import MovterNetwork

struct AuthCredentials {
    let method: AuthMethod
    let contact: String

    init(method: AuthMethod, contact: String) {
        self.method = method
        self.contact = contact
    }

    func toDTO() -> AuthCredentialsDTO {
        AuthCredentialsDTO(method: method.toDTO(), contact: contact)
    }
}
