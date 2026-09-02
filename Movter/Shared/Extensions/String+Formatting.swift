//
//  String+Formatting.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

extension String {
    /// "Dune  ·  2021", or the title alone when the year is unknown. The separator lives
    /// here so the diary and the watchlist can't drift apart on spacing.
    nonisolated func withYear(_ year: String?) -> String {
        guard let year = year, !year.isEmpty else { return self }
        return "\(self)  ·  \(year)"
    }
}
