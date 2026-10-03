//
//  CoachMarksStore.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

enum CoachMarksStore {
    private static let seenKey = "coach_marks_tour_seen_v1"
    private static let roleSelectionSeenKey = "coach_marks_role_selection_seen_v1"

    static var hasSeenRoleSelectionHints: Bool {
        UserDefaults.standard.bool(forKey: roleSelectionSeenKey)
    }

    static func markRoleSelectionHintsSeen() {
        UserDefaults.standard.set(true, forKey: roleSelectionSeenKey)
    }

    static func hasSeenTour(isMentor: Bool) -> Bool {
        UserDefaults.standard.bool(forKey: key(isMentor: isMentor))
    }

    static func markTourSeen(isMentor: Bool) {
        UserDefaults.standard.set(true, forKey: key(isMentor: isMentor))
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key(isMentor: true))
        UserDefaults.standard.removeObject(forKey: key(isMentor: false))
        UserDefaults.standard.removeObject(forKey: roleSelectionSeenKey)
    }

    private static func key(isMentor: Bool) -> String {
        "\(seenKey)_\(isMentor ? "mentor" : "mentee")"
    }
}
