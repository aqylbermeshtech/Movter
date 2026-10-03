//
//  CoachMarkAnchorRegistry.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import UIKit

final class CoachMarkAnchorRegistry {
    static let shared = CoachMarkAnchorRegistry()

    private var frames: [String: CGRect] = [:]

    private init() {}

    func setFrame(_ frame: CGRect, for id: String) {
        frames[id] = frame
    }

    func removeFrame(for id: String) {
        frames[id] = nil
    }

    func frame(for id: String) -> CGRect? {
        guard let frame = frames[id], frame.width > 1, frame.height > 1 else { return nil }
        return frame
    }
}
