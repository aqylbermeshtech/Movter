//
//  TopFavoritesSectionView.swift
//  Movter
//
//  Created by Nurtore on 15.11.2026.
//

import SwiftUI
import UIKit

struct TopFavoritesSectionView: View {
    let favorites: [FavoriteFilm]
    let onAddTap: () -> Void
    let onSelectFilm: (FavoriteFilm) -> Void
    let onRemoveTap: (Int) -> Void

    private static let maxSlots = 4
    private static let cardWidth: CGFloat = 104
    private static let cardHeight: CGFloat = 156

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onAddTap) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Top 4 Movies")
                            .font(Font(UIFont.sectionHeaderStrong))
                            .foregroundStyle(Color(uiColor: .textPrimary))

                        Text("Your favorites")
                            .font(Font(UIFont.secondaryBody))
                            .foregroundStyle(Color(uiColor: .textSecondary))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .textSecondary))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<Self.maxSlots, id: \.self) { index in
                        if let film = favorites[safe: index] {
                            Button {
                                onSelectFilm(film)
                            } label: {
                                FavoritePosterCard(film: film)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    onRemoveTap(film.id)
                                } label: {
                                    Label("Remove from Top 4", systemImage: "trash")
                                }
                            }
                        } else {
                            emptySlot(showsPlus: index == favorites.count)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func emptySlot(showsPlus: Bool) -> some View {
        Button(action: onAddTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        Color(uiColor: .textSecondary).opacity(0.45),
                        style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])
                    )

                if showsPlus {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(Color(uiColor: .textSecondary))
                }
            }
            .frame(width: Self.cardWidth, height: Self.cardHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct FavoritePosterCard: View {
    let film: FavoriteFilm

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(uiColor: .surface)
                    Image(systemName: "film")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(uiColor: .textSecondary))
                }
            }
        }
        .frame(width: 104, height: 156)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .task(id: film.id) {
            guard let url = film.posterURL else { return }
            image = await withCheckedContinuation { continuation in
                ImageLoader.load(url: url) { loaded in
                    continuation.resume(returning: loaded)
                }
            }
        }
    }
}
