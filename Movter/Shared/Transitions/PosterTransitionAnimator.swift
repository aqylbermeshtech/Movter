//
//  PosterTransitionAnimator.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import UIKit

final class PosterTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    enum Direction { case push, pop }

    private static let pushDuration: TimeInterval = 0.5
    private static let popDuration: TimeInterval = 0.42
    private static let damping: CGFloat = 0.86
    private static let handoffPoint: CGFloat = 0.65
    private static let copyFadePoint: CGFloat = 0.85

    private let direction: Direction
    private let anchor: PosterTransitionAnchor

    init(direction: Direction, anchor: PosterTransitionAnchor) {
        self.direction = direction
        self.anchor = anchor
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        direction == .push ? Self.pushDuration : Self.popDuration
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let fromVC = context.viewController(forKey: .from),
              let toVC = context.viewController(forKey: .to),
              let toView = toVC.view,
              let fromView = fromVC.view
        else {
            context.completeTransition(false)
            return
        }

        let container = context.containerView
        let isPush = direction == .push

        if isPush {
            container.addSubview(toView)
        } else {
            container.insertSubview(toView, belowSubview: fromView)
        }
        toView.frame = context.finalFrame(for: toVC)
        toView.layoutIfNeeded()

        let detailsView = isPush ? toView : fromView
        guard let details = (isPush ? toVC : fromVC) as? PosterTransitionDestination else {
            context.completeTransition(false)
            return
        }

        let detailsPoster = details.transitionPoster
        let gridPoster = anchor.view
        let gridFrame = container.convert(gridPoster.bounds, from: gridPoster)
        let detailsFrame = container.convert(detailsPoster.bounds, from: detailsPoster)

        let image = isPush
            ? (gridPoster.image ?? detailsPoster.image)
            : (detailsPoster.image ?? gridPoster.image)

        if detailsPoster.image == nil {
            detailsPoster.image = image
        }

        let copy = UIImageView(image: image)
        copy.contentMode = .scaleAspectFill
        copy.clipsToBounds = true
        copy.backgroundColor = .surface
        copy.layer.cornerCurve = .continuous
        copy.layer.cornerRadius = isPush ? anchor.cornerRadius : 0
        copy.frame = isPush ? gridFrame : detailsFrame
        container.addSubview(copy)

        gridPoster.alpha = 0
        detailsPoster.alpha = 0
        detailsView.alpha = isPush ? 0 : 1

        let animator = UIViewPropertyAnimator(
            duration: transitionDuration(using: context),
            dampingRatio: Self.damping
        ) {
            copy.frame = isPush ? detailsFrame : gridFrame
            copy.layer.cornerRadius = isPush ? 0 : self.anchor.cornerRadius
            detailsView.alpha = isPush ? 1 : 0
        }

        animator.addAnimations({
            if isPush { detailsPoster.alpha = 1 } else { gridPoster.alpha = 1 }
        }, delayFactor: Self.handoffPoint)
        animator.addAnimations({ copy.alpha = 0 }, delayFactor: Self.copyFadePoint)

        animator.addCompletion { _ in
            copy.removeFromSuperview()
            gridPoster.alpha = 1
            detailsPoster.alpha = 1
            detailsView.alpha = 1
            context.completeTransition(!context.transitionWasCancelled)
        }

        animator.startAnimation()
    }
}
