//
//  EmailOTPSendResponse.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

public struct EmailOTPSendResponse: Codable {
    public let success: Bool
    public let message: String?
    public let data: EmailOTPSendData?
    
    public init(success: Bool, message: String? = nil, data: EmailOTPSendData? = nil) {
        self.success = success
        self.message = message
        self.data = data
    }
}

public struct EmailOTPSendData: Codable {
    public let message: String?
    
    public init(message: String? = nil) {
        self.message = message
    }
}

