//
//  UpsetRobotIllustration.swift
//  Movter
//
//  Created by Nurtore on 25.08.2026.
//

import UIKit

/// A small line-art robot for the deck's paused/empty states — drawn as vectors, the
/// same approach `RatingStar` uses for the rating glyph, so it scales cleanly at any
/// size without a bundled image asset.
enum UpsetRobotIllustration {

    private static let cache = NSCache<NSString, UIImage>()

    static func image(pointSize: CGFloat, color: UIColor = .textSecondary) -> UIImage {
        let key = "\(pointSize)-\(color.hashValue)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let size = CGSize(width: pointSize, height: pointSize)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size), color: color)
        }.withRenderingMode(.alwaysOriginal)

        cache.setObject(image, forKey: key)
        return image
    }

    /// Coordinates are fractions of `rect`, carried over from an SVG prototype of the
    /// same figure: rounded-square head, a drooping antenna, downcast brows, dot
    /// eyes, a frown, and small hanging arms and legs.
    private static func draw(in rect: CGRect, color: UIColor) {
        let w = rect.width
        let h = rect.height
        func point(_ fx: CGFloat, _ fy: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + fx * w, y: rect.minY + fy * h)
        }

        color.setStroke()
        color.setFill()
        let strokeWidth = max(1.5, w * 0.03)

        func strokeLine(from: CGPoint, to: CGPoint, width: CGFloat) {
            let path = UIBezierPath()
            path.move(to: from)
            path.addLine(to: to)
            path.lineWidth = width
            path.lineCapStyle = .round
            path.stroke()
        }

        func fillDot(at center: CGPoint, radius: CGFloat) {
            UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true).fill()
        }

        // Antenna, leaning off-center — a dejected posture rather than standing straight.
        strokeLine(from: point(0.5, 0.243), to: point(0.366, 0.0395), width: strokeWidth)
        fillDot(at: point(0.366, 0.0395), radius: w * 0.043)

        // Head.
        let head = UIBezierPath(
            roundedRect: CGRect(x: rect.minX + 0.134 * w, y: rect.minY + 0.243 * h, width: 0.732 * w, height: 0.621 * h),
            cornerRadius: 0.134 * w
        )
        head.lineWidth = strokeWidth
        head.stroke()

        // Arms and legs, hanging rather than raised.
        strokeLine(from: point(0.134, 0.695), to: point(0, 0.853), width: strokeWidth)
        strokeLine(from: point(0.866, 0.695), to: point(1, 0.853), width: strokeWidth)
        strokeLine(from: point(0.293, 0.864), to: point(0.293, 1.0), width: strokeWidth)
        strokeLine(from: point(0.707, 0.864), to: point(0.707, 1.0), width: strokeWidth)

        // Eyebrows angled down toward the center — the "upset" cue.
        let browWidth = max(1, w * 0.024)
        strokeLine(from: point(0.244, 0.401), to: point(0.384, 0.469), width: browWidth)
        strokeLine(from: point(0.756, 0.401), to: point(0.616, 0.469), width: browWidth)

        // Eyes.
        fillDot(at: point(0.360, 0.537), radius: w * 0.0396)
        fillDot(at: point(0.640, 0.537), radius: w * 0.0396)

        // Mouth: a frown — the control point sits above the corners, so the curve
        // domes upward in the middle while the corners droop.
        let mouth = UIBezierPath()
        mouth.move(to: point(0.329, 0.763))
        mouth.addQuadCurve(to: point(0.671, 0.763), controlPoint: point(0.5, 0.672))
        mouth.lineWidth = browWidth * 1.2
        mouth.lineCapStyle = .round
        mouth.stroke()
    }
}
