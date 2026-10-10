//
//  PosterTransitionController.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import UIKit

final class PosterTransitionController: NSObject, UINavigationControllerDelegate {

    private static let minimumVisiblePosterHeight: CGFloat = 80

    private weak var source: (UIViewController & PosterTransitionSource)?
    private var mediaID: Int?
    private var isPushPending = false

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
            let swipe = navigationController.interactivePopGestureRecognizer?.state
            guard swipe != .began, swipe != .changed else { return nil }
            guard toVC === source, let details = fromVC as? PosterTransitionDestination else { return nil }

            let poster = details.transitionPoster
            let visible = fromVC.view.convert(poster.bounds, from: poster)
            guard visible.maxY > Self.minimumVisiblePosterHeight else { return nil }

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
        isPushPending = false

        if viewController === source {
            reset(clearing: navigationController)
        }
    }
}
