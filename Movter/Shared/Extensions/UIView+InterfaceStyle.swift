//
//  UIView+InterfaceStyle.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import UIKit

extension UIView {
    /// Keeps a `CGColor`-valued layer property in step with the interface style.
    ///
    /// A `CGColor` carries no traits, so a dynamic `UIColor` flattened into one freezes at
    /// whatever style was current when it was set — a border picked in dark mode stays
    /// dark once the page turns white. Everything set through `backgroundColor`,
    /// `textColor` and friends re-resolves on its own; only the layer needs this.
    ///
    /// `update` is handed the view so it never has to capture one, which would retain the
    /// view through the registration it owns.
    func trackInterfaceStyle(_ update: @escaping (UIView) -> Void) {
        update(self)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: UIView, _: UITraitCollection) in
            update(view)
        }
    }
}
