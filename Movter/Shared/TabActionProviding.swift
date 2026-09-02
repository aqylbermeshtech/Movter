//
//  TabActionProviding.swift
//  Movter
//
//  Created by Nurtore on 25.08.2026.
//

import UIKit

/// A tab's root screen supplying the one action its floating action button performs.
///
/// The button morphs to the active tab's `tabActionSymbol` and forwards taps to
/// `performTabAction()`, so each screen's primary action lives on the screen that owns
/// it rather than in the tab bar.
protocol TabActionProviding: UIViewController {
    var tabActionSymbol: String { get }
    var tabActionLabel: String { get }
    func performTabAction()
}
