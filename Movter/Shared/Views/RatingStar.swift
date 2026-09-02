//
//  RatingStar.swift
//  Movter
//
//  Created by Nurtore on 18.08.2026.
//

import UIKit

/// The rating star, drawn as a vector rather than an asset or the emoji glyph, so it
/// tints from the palette and looks identical on every OS version.
enum RatingStar {

    /// Inner/outer radius ratio. The textbook 0.382 goes spindly at label sizes.
    private static let innerRadiusRatio: CGFloat = 0.47

    private static let cache = NSCache<NSString, UIImage>()

    static func image(pointSize: CGFloat, color: UIColor = .accent) -> UIImage {
        let key = "\(pointSize)-\(color.hashValue)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let size = CGSize(width: pointSize, height: pointSize)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            let path = starPath(in: CGRect(origin: .zero, size: size))
            color.setFill()
            color.setStroke()
            path.fill()
            // Round join softens the tips, which otherwise alias into fuzz when small.
            path.lineWidth = pointSize * 0.07
            path.lineJoinStyle = .round
            path.stroke()
        }.withRenderingMode(.alwaysOriginal)

        cache.setObject(image, forKey: key)
        return image
    }

    private static func starPath(in rect: CGRect) -> UIBezierPath {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        // Inset by the stroke so the rounded tips stay inside the image bounds.
        let outerRadius = rect.width / 2 - rect.width * 0.045
        let innerRadius = outerRadius * innerRadiusRatio

        let path = UIBezierPath()
        for corner in 0..<5 {
            let tipAngle = -CGFloat.pi / 2 + CGFloat(corner) * 2 * .pi / 5
            let valleyAngle = tipAngle + .pi / 5

            let tip = CGPoint(
                x: center.x + cos(tipAngle) * outerRadius,
                y: center.y + sin(tipAngle) * outerRadius
            )
            let valley = CGPoint(
                x: center.x + cos(valleyAngle) * innerRadius,
                y: center.y + sin(valleyAngle) * innerRadius
            )

            corner == 0 ? path.move(to: tip) : path.addLine(to: tip)
            path.addLine(to: valley)
        }
        path.close()
        return path
    }
}
