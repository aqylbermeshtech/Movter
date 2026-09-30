//
//  RequestMethod.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Foundation

/// Custom HTTP method enum for Clean Architecture
/// Note: Named RequestMethod to avoid conflict with Alamofire.HTTPMethod
nonisolated public enum RequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

