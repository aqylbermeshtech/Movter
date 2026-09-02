//
//  MediaType.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

enum MediaType: String, Hashable, CaseIterable {
    case movie
    case tv

    var path: String { rawValue }
}
