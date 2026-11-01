//
//  MediaQuerySource.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

enum MediaQuerySource {
    case discover(DiscoverQuery)
    case search(String)
    case unsupported
}
