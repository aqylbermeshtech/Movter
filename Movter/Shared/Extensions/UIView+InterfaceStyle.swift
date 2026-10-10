//
//  UIView+InterfaceStyle.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import UIKit

extension UIView {
    func trackInterfaceStyle(_ update: @escaping (UIView) -> Void) {
        update(self)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: UIView, _: UITraitCollection) in
            update(view)
        }
    }
}
