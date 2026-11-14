//
//  StackedStubsDeckView.swift
//  Movter
//

import SwiftUI
import UIKit

struct StackedStubsDeckView: View {
    let reviews: [Review]
    let loadArtwork: (Review) async -> (poster: UIImage?, logo: UIImage?)
    let onTap: () -> Void

    private static let angles: [Double] = [-1.8, 2.6, -3.5, 4.2]
    private static let offsets: [CGSize] = [
        CGSize(width: 0, height: 0),
        CGSize(width: 5, height: 6),
        CGSize(width: -5, height: 11),
        CGSize(width: 7, height: 16)
    ]

    var body: some View {
        Button(action: onTap) {
            ZStack {
                ForEach(Array(reviews.enumerated()).reversed(), id: \.element.id) { index, review in
                    StackedStubLayerView(
                        review: review,
                        depthIndex: index,
                        angle: Self.angles[min(index, Self.angles.count - 1)],
                        offset: Self.offsets[min(index, Self.offsets.count - 1)],
                        loadArtwork: loadArtwork
                    )
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct StackedStubLayerView: View {
    let review: Review
    let depthIndex: Int
    let angle: Double
    let offset: CGSize
    let loadArtwork: (Review) async -> (poster: UIImage?, logo: UIImage?)

    @State private var posterImage: UIImage?
    @State private var logoImage: UIImage?

    var body: some View {
        TicketStubView(
            review: review,
            posterImage: posterImage,
            logoImage: logoImage
        )
        .brightness(-Double(depthIndex) * 0.06)
        .rotationEffect(.degrees(angle))
        .offset(offset)
        .shadow(
            color: .black.opacity(depthIndex == 0 ? 0.52 : 0.36),
            radius: depthIndex == 0 ? 12 : 8,
            x: 0,
            y: depthIndex == 0 ? 6 : 4
        )
        .task(id: review.id) {
            guard depthIndex == 0 else { return }
            let result = await loadArtwork(review)
            posterImage = result.poster
            logoImage = result.logo
        }
    }
}
