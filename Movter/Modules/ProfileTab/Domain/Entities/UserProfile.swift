//
//  UserProfile.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import Foundation

public struct UserProfile: Equatable {
    // MARK: - Nested Stats Entity
        
    public struct Stats: Equatable {
        public let watchedCount: Int
        public let reviewsCount: Int
        public let watchlistCount: Int
        public init(
            watchedCount: Int = 0,
            reviewsCount: Int = 0,
            watchlistCount: Int = 0
        ) {
            self.watchedCount = watchedCount
            self.reviewsCount = reviewsCount
            self.watchlistCount = watchlistCount
        }

        public static let zero = Stats(watchedCount: 0, reviewsCount: 0, watchlistCount: 0)
    }

    public let id: String
    public let name: String
    public let email: String
    public let avatarURL: URL?
    public let memberSinceDate: Date?
    public let stats: Stats
    
    public init(
        id: String,
        name: String,
        email: String,
        avatarURL: URL?,
        memberSinceDate: Date? = nil,
        stats: Stats = .zero
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.memberSinceDate = memberSinceDate
        self.stats = stats
    }
}

public typealias ProfileStats = UserProfile.Stats
