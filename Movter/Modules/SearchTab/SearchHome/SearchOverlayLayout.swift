//
//  SearchOverlayLayout.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import UIKit

/// The search overlay's compositional layout.
///
/// Takes its two inputs as closures rather than holding the controller: the layout is
/// built before the diffable data source exists, and the chips section's height depends
/// on recents that change while the screen is open.
struct SearchOverlayLayout {

    /// The margin the header, rows and chips all align to.
    static let sideInset: CGFloat = 16

    /// Which section sits at a given index. Only the data source knows, and it isn't
    /// created until after the layout has been handed to the collection view.
    let section: (Int) -> SearchOverlayViewModel.Section?
    /// The chips wrap to fit, so the group's height is a function of the terms in it.
    let recents: () -> [String]

    func make() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { index, environment in
            switch section(index) {
            case .chips:
                return chipsSection(environment)
            case .query:
                return rowsSection(rowHeight: 58, hasHeader: false)
            case .recentRows:
                return rowsSection(rowHeight: 52, hasHeader: true)
            case .trending:
                return rowsSection(rowHeight: 52, hasHeader: true)
            case .skeleton:
                return rowsSection(rowHeight: 44, hasHeader: true)
            case .none:
                // Not reachable for a live section index; a compositional layout
                // provider isn't allowed to return nil, so hand back an empty section.
                return rowsSection(rowHeight: 0, hasHeader: false)
            }
        }
    }

    // MARK: - Sections

    private func rowsSection(rowHeight: CGFloat, hasHeader: Bool) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(1), heightDimension: .absolute(rowHeight)
        ))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(rowHeight)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: Self.sideInset, bottom: 0, trailing: Self.sideInset)
        if hasHeader { section.boundarySupplementaryItems = [Self.headerItem()] }
        return section
    }

    private func chipsSection(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let available = environment.container.effectiveContentSize.width - Self.sideInset * 2
        let (frames, totalHeight) = Self.chipFrames(for: recents(), availableWidth: available)

        let group = NSCollectionLayoutGroup.custom(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(max(totalHeight, 1)))
        ) { _ in frames }

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 4, leading: Self.sideInset, bottom: 20, trailing: Self.sideInset)
        section.boundarySupplementaryItems = [Self.headerItem()]
        return section
    }

    private static func headerItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }

    /// Wraps the recent chips into lines that fit `availableWidth`, returning each
    /// chip's frame (in the group's own coordinate space) and the total stack height.
    /// Pure and deterministic — the compositional layout calls it once for the group
    /// height and again for the item frames.
    private static func chipFrames(
        for terms: [String], availableWidth: CGFloat
    ) -> (frames: [NSCollectionLayoutGroupCustomItem], height: CGFloat) {
        let chipHeight: CGFloat = 34
        let lineSpacing: CGFloat = 10
        let interItemSpacing: CGFloat = 8

        var frames: [NSCollectionLayoutGroupCustomItem] = []
        var x: CGFloat = 0
        var y: CGFloat = 0

        for term in terms {
            let width = min(ChipCell.width(for: term), availableWidth)
            if x > 0, x + width > availableWidth {
                x = 0
                y += chipHeight + lineSpacing
            }
            frames.append(.init(frame: CGRect(x: x, y: y, width: width, height: chipHeight)))
            x += width + interItemSpacing
        }

        let height = terms.isEmpty ? 0 : y + chipHeight
        return (frames, height)
    }
}
