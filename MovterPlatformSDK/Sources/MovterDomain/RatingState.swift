//
//  RatingState.swift
//  MovterDomain
//
//  Created by Nurtore on 18.08.2026.
//

import Foundation

public enum RatingState: Equatable, Sendable {
    case rated(score: Double, votes: Int)
    case provisional(score: Double, votes: Int)
    case unrated
    case upcoming(releaseDate: Date?)

    public static let confidentVoteThreshold = 10

    public var isUpcoming: Bool {
        if case .upcoming = self { return true }
        return false
    }

    public init(voteAverage: Double, voteCount: Int, releaseDate: String?) {
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
