//
//  Array+Safe.swift
//  Movter
//
//  Created by Nurtore on 18.08.2026.
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
