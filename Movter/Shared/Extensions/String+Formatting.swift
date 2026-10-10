//
//  String+Formatting.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

extension String {
    func withYear(_ year: String?) -> String {
        guard let year = year, !year.isEmpty else { return self }
        return "\(self)  ·  \(year)"
    }
}
