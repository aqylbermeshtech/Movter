//
//  ReviewSummary.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

struct ReviewSummary: Equatable {
    let count: Int
    let averageScore: Double

    init(reviews: [Review]) {
        self.count = reviews.count
        guard !reviews.isEmpty else {
            self.averageScore = 0.0
            return
        }
        self.averageScore = Double(reviews.reduce(0) { $0 + $1.score }) / Double(reviews.count)
    }

    init(count: Int, averageScore: Double) {
        self.count = count
        self.averageScore = averageScore
    }

    var displayText: String {
        guard count > 0 else { return "" }
        let filmCount = "\(count) film\(count == 1 ? "" : "s")"
        return String(format: "%@  ·  %.1f average", filmCount, averageScore)
    }
}
