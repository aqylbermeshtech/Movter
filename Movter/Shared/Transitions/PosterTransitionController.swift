//
//  PosterTransitionController.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import UIKit

/// Drives the poster flight for one screen's pushes into `MediaDetailsViewController`.
///
/// Owned by the screen doing the pushing rather than installed once on the navigation
/// controller: the animation needs the poster that was actually tapped, and only the
/// source screen can find it. Each source installs itself as the navigation delegate
/// for the duration of its own flight and steps back out afterwards, so a stack with
/// several poster screens in it never has two of these competing.
///
/// Every guard falls back to the standard push instead of failing: a transition that
/// can't find its poster should look ordinary, not broken.
final class PosterTransitionController: NSObject, UINavigationControllerDelegate {

    /// A pop that starts more than this far up the screen has no poster left to fly
    /// from — the header has scrolled up behind the navigation bar.
    private static let minimumVisiblePosterHeight: CGFloat = 80

    private weak var source: (UIViewController & PosterTransitionSource)?
    /// The title in flight, and the id the matching pop flies back into.
    private var mediaID: Int?
    /// Set only for the push this controller initiated. Without it a later plain push
    /// onto the same stack — "Surprise me" picks a random title — would be animated as
    /// a flight out of whatever poster happened to still be under `mediaID`.
    private var isPushPending = false

    /// Pushes `details` with the poster flight, falling back to the standard push when
    /// the tapped poster isn't on screen to fly out of.
    func push(
        _ details: UIViewController & PosterTransitionDestination,
        for media: Media,
        from source: UIViewController & PosterTransitionSource
    ) {
        guard let navigationController = source.navigationController else { return }

        if source.transitionPoster(forMediaID: media.id) != nil {
            self.source = source
            mediaID = media.id
            isPushPending = true
            navigationController.delegate = self
        } else {
            reset(clearing: navigationController)
        }

        navigationController.pushViewController(details, animated: true)
    }

    private func reset(clearing navigationController: UINavigationController?) {
        source = nil
        mediaID = nil
        isPushPending = false
        if navigationController?.delegate === self {
            navigationController?.delegate = nil
        }
    }

    // MARK: - UINavigationControllerDelegate

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let source = source,
              let mediaID = mediaID,
              let anchor = source.transitionPoster(forMediaID: mediaID)
        else { return nil }

        switch operation {
        case .push:
            guard isPushPending, fromVC === source, toVC is PosterTransitionDestination else { return nil }
            return PosterTransitionAnimator(direction: .push, anchor: anchor)

        case .pop:
            // Swipe-back stays native. A custom animator here would also need an
            // interaction controller to follow the finger, and a flight that only half
            // tracks the gesture is worse than the standard slide.
            let swipe = navigationController.interactivePopGestureRecognizer?.state
            guard swipe != .began, swipe != .changed else { return nil }
            guard toVC === source, let details = fromVC as? PosterTransitionDestination else { return nil }

            let poster = details.transitionPoster
            let visible = fromVC.view.convert(poster.bounds, from: poster)
            guard visible.maxY > Self.minimumVisiblePosterHeight else { return nil }

            // Likewise at the other end: the grid may have been scrolled since the push,
            // leaving the cell off screen even though it's still "visible" to its own
            // collection view.
            let landing = source.view.convert(anchor.view.bounds, from: anchor.view)
            guard source.view.bounds.intersects(landing) else { return nil }

            return PosterTransitionAnimator(direction: .pop, anchor: anchor)

        default:
            return nil
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        // The push has landed; what's left is armed for the matching pop only.
        isPushPending = false

        // Back on the source screen, the flight is spent. Anything pushed from here on
        // belongs to whoever pushes it.
        if viewController === source {
            reset(clearing: navigationController)
        }
    }
}
