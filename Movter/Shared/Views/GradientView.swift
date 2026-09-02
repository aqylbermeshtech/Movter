//
//  GradientView.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import UIKit

/// A view whose backing layer *is* the gradient, so it resizes with Auto Layout rather
/// than needing frame bookkeeping in `layoutSubviews`, and its place in the hierarchy is
/// explicit — a `CAGradientLayer` added as a sublayer of a `UIImageView` draws behind
/// the image it was meant to be covering.
final class GradientView: UIView {

    override class var layerClass: AnyClass { CAGradientLayer.self }

    /// For gradients whose colours change after init — a scrim that has to repaint when
    /// the theme flips the tone underneath it.
    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    init(colors: [UIColor] = [], locations: [NSNumber] = []) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.locations = locations
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
