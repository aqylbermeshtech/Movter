//
//  UINavigationController+InteractivePop.swift
//  Movter
//
//  Created by Nurtore on 13.11.2026.
//

import UIKit

@MainActor
final class InteractivePopGestureDelegate: NSObject, UIGestureRecognizerDelegate {

    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = navigationController else { return false }
        // Only allow edge-swipe pop when there is more than one view controller on the stack.
        // Allowing on root (count <= 1) freezes the navigation controller in UIKit.
        guard nav.viewControllers.count > 1 else { return false }

        // Require rightward, predominantly horizontal swipe to avoid hijacking vertical scroll
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = pan.velocity(in: nav.view)
            if velocity.x != 0 || velocity.y != 0 {
                guard velocity.x > 0, abs(velocity.x) > abs(velocity.y) else {
                    return false
                }
            }
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard otherGestureRecognizer !== gestureRecognizer else { return false }
        // Child pan gestures (e.g. horizontal collection views, carousels, web views)
        // must yield to the edge-swipe gesture when the touch begins at the screen edge.
        return otherGestureRecognizer is UIPanGestureRecognizer && !(otherGestureRecognizer is UIScreenEdgePanGestureRecognizer)
    }
}

public extension UIViewController {

    private static var interactivePopDelegateKey: UInt8 = 0

    func enableInteractivePopGesture() {
        guard let nav = (self as? UINavigationController) ?? self.navigationController else { return }
        nav.interactivePopGestureRecognizer?.isEnabled = true
        if let existing = objc_getAssociatedObject(nav, &Self.interactivePopDelegateKey) as? InteractivePopGestureDelegate {
            nav.interactivePopGestureRecognizer?.delegate = existing
            return
        }
        let delegate = InteractivePopGestureDelegate(navigationController: nav)
        objc_setAssociatedObject(nav, &Self.interactivePopDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        nav.interactivePopGestureRecognizer?.delegate = delegate
    }
}
