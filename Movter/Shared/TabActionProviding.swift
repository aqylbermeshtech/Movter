//
//  TabActionProviding.swift
//  Movter
//
//  Created by Nurtore on 25.08.2026.
//

import UIKit

protocol TabActionProviding: UIViewController {
    var tabActionSymbol: String { get }
    var tabActionLabel: String { get }
    func performTabAction()
}
