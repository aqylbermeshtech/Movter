//
//  ParseStrategy.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

public protocol ParseStrategy {
    var data: Data? { get set }
    var response: URLResponse? { get set }

    init(_ data: Data?, _ response: URLResponse?)
    func parse<T: Codable>() async throws -> T?
}
