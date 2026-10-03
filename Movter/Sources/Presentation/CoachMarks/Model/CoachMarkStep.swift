//
//  CoachMarkStep.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

struct CoachMarkStep {
    let tab: TabBarType?
    let anchorId: String?
    let title: String
    let message: String
    var skipsWhenAnchorMissing: Bool = false
}
