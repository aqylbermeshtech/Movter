//
//  EndPointType.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Foundation

nonisolated public protocol EndPointType {
    var baseURL: URL { get }
    var path: String { get }
    var httpMethod: RequestMethod { get }
    var task: RequestTask { get }
    var headers: RequestHeaders? { get }
}
