//
//  Foundation+Extensions.swift
//  Movter
//
//  Created by Nurtore on 22.09.2026.
//

import Foundation

// MARK: - String Extensions
public extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

