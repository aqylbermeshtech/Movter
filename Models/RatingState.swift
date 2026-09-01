//
//  RatingState.swift
//  Movter
//
//  Created by Nurtore on 18.08.2026.
//

import Foundation

nonisolated enum RatingState {
    case rated(score: Double, votes: Int)
    case provisional(score: Double, votes: Int)
    case unrated
    case upcoming(releaseDate: Date?)

    static let confidentVoteThreshold = 10

    init(voteAverage: Double, voteCount: Int, releaseDate: String?) {
        let date = releaseDate.flatMap { Self.isoFormatter.date(from: $0) }

        guard voteCount > 0 else {
            guard let date = date else {
                self = .upcoming(releaseDate: nil)
                return
            }
            self = date > Date() ? .upcoming(releaseDate: date) : .unrated
            return
        }

        self = voteCount < Self.confidentVoteThreshold
            ? .provisional(score: voteAverage, votes: voteCount)
            : .rated(score: voteAverage, votes: voteCount)
    }

    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
