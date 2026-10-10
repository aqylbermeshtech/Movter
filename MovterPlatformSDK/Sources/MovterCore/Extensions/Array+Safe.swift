//
//  Array+Safe.swift
//  MovterCore
//
//  Created by Nurtore on 18.08.2026.
//

import Foundation

public extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
