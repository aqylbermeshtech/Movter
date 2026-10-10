//
//  String+Formatting.swift
//  MovterCore
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

public extension String {
    func withYear(_ year: String?) -> String {
        guard let year = year, !year.isEmpty else { return self }
        return "\(self)  ·  \(year)"
    }
}
