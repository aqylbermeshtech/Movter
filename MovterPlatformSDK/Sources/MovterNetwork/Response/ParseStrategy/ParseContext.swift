//
//  ParseContext.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

nonisolated public class ParseContext {
    private var parseStrategy: ParseStrategy
    
    public init(parseStrategy: ParseStrategy) {
        self.parseStrategy = parseStrategy
    }
    
    public func process<T: Codable>() async throws -> T? {
        try await parseStrategy.parse()
    }
}
