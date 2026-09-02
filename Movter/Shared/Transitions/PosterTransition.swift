//
//  PosterTransition.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import UIKit

/// A poster on a source screen, paired with the corner radius the flight has to match.
///
/// The radius travels with the anchor because each surface rounds its artwork
/// differently — 12 in the grids, 16 on the hero card, 20 on a swipe card — and the
/// flight has to start from whichever rounding it actually left.
struct PosterTransitionAnchor {
    let view: UIImageView
    let cornerRadius: CGFloat
}

/// A screen a poster can fly out of: a grid, a carousel, or the swipe deck.
///
/// The lookup is by id rather than by a view captured at push time. By the time the
/// details screen is popped the cell may have been reused, scrolled away or reloaded,
/// and a stale reference would fly the poster back into whatever title now sits there.
protocol PosterTransitionSource: AnyObject {
    func transitionPoster(forMediaID id: Int) -> PosterTransitionAnchor?
}

/// The details screen the poster settles into.
protocol PosterTransitionDestination: AnyObject {
    var transitionPoster: UIImageView { get }
}

extension UICollectionView {
    /// The visible `MediaCell` showing `id`, if there is one. Only visible cells count:
    /// an off-screen cell has no frame worth flying to, and callers fall back to the
    /// standard push when this returns nil.
    ///
    /// - Parameter mediaID: maps an item index to the id displayed there, since the
    ///   collection view itself knows nothing about what its cells are showing.
    func mediaPosterAnchor(forMediaID id: Int, mediaID: (Int) -> Int?) -> PosterTransitionAnchor? {
        for indexPath in indexPathsForVisibleItems where mediaID(indexPath.item) == id {
            guard let cell = cellForItem(at: indexPath) as? MediaCell else { continue }
            return cell.posterAnchor
        }
        return nil
    }
}
