//
//  PosterTransition.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import UIKit

struct PosterTransitionAnchor {
    let view: UIImageView
    let cornerRadius: CGFloat
}

protocol PosterTransitionSource: AnyObject {
    func transitionPoster(forMediaID id: Int) -> PosterTransitionAnchor?
}

protocol PosterTransitionDestination: AnyObject {
    var transitionPoster: UIImageView { get }
}

extension UICollectionView {
    func mediaPosterAnchor(forMediaID id: Int, mediaID: (Int) -> Int?) -> PosterTransitionAnchor? {
        for indexPath in indexPathsForVisibleItems where mediaID(indexPath.item) == id {
            guard let cell = cellForItem(at: indexPath) as? MediaCell else { continue }
            return cell.posterAnchor
        }
        return nil
    }
}
