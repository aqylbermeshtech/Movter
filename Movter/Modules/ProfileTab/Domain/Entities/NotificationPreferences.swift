//
//  NotificationPreferences.swift
//  Movter
//
//  Created by Nurtore on 18.08.2026.
//

import Foundation

public enum NotificationPreference: String, CaseIterable, Sendable {
    case newTrailers
    case weeklyDigest
    case filmNews

    public var title: String {
        switch self {
        case .newTrailers: return "New Trailers"
        case .weeklyDigest: return "Weekly Digest"
        case .filmNews: return "Film News"
        }
    }

    public var subtitle: String {
        switch self {
        case .newTrailers: return "When a film you viewed gets a trailer"
        case .weeklyDigest: return "A summary of what's trending each week"
        case .filmNews: return "Latest articles from the news feed"
        }
    }

    public var defaultValue: Bool {
        switch self {
        case .newTrailers: return true
        case .weeklyDigest: return true
        case .filmNews: return false
        }
    }
}

public enum NotificationAuthorizationStatus: Sendable {
    case notDetermined
    case authorized
    case denied
    case temporary
    case unknown
    public var isAuthorized: Bool {
        self == .authorized || self == .temporary
    }
}

