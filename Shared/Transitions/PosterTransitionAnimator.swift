//
//  PosterTransitionAnimator.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import UIKit

/// Flies the tapped poster into the details screen's header, and back out again.
///
/// Neither real poster moves: a throwaway copy flies between the two frames while the
/// originals are held transparent. That way no screen's layout is disturbed by the
/// animation, and a cancelled transition has nothing to undo beyond restoring alpha.
final class PosterTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    enum Direction { case push, pop }

    /// Slower on the way in: the poster is growing into a screen the viewer hasn't seen
    /// yet, and the same speed coming back out reads as sluggish once they have.
    private static let pushDuration: TimeInterval = 0.5
    private static let popDuration: TimeInterval = 0.42
    /// Enough give to feel physical, not so much that the poster visibly wobbles.
    private static let damping: CGFloat = 0.86
    /// The real poster fades up under the copy before the flight lands, so artwork that
    /// changes on the way — the hero card is a backdrop, the header is a poster —
    /// cross-dissolves instead of snapping at the end.
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

        // The incoming view goes in first and is laid out immediately: on a push the
        // details screen has never been on screen, so its poster has no frame to fly to
        // until this happens.
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

        // Prefer whichever end the flight starts from — on the way back that's the
        // large header artwork, which is the sharper image of the two.
        let image = isPush
            ? (gridPoster.image ?? detailsPoster.image)
            : (detailsPoster.image ?? gridPoster.image)

        // The header loads its artwork at a larger size and may not have it back yet.
        // Standing the flying image in behind it means the poster never lands in an empty
        // box; the real artwork replaces it as soon as it arrives.
        if detailsPoster.image == nil {
            detailsPoster.image = image
        }

        let copy = UIImageView(image: image)
        // Fill rather than fit at both ends, so a poster that changes aspect on the way
        // crops into its new shape instead of stretching.
        copy.contentMode = .scaleAspectFill
        copy.clipsToBounds = true
        copy.backgroundColor = .surface
        copy.layer.cornerCurve = .continuous
        copy.layer.cornerRadius = isPush ? anchor.cornerRadius : 0
        copy.frame = isPush ? gridFrame : detailsFrame
        container.addSubview(copy)

        // Both originals stay out of the way for the whole flight; the copy is the only
        // poster on screen until the hand-off.
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

        // Whichever poster the flight is landing on comes back first, then the copy
        // fades off the top of it.
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
