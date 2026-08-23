//
//  SkeletonGridView.swift
//  Movter
//
//  Created by Nurtore on 22.08.2026.
//

import UIKit

/// Placeholder shapes for poster content that hasn't loaded yet.
///
/// Timing matters more than the drawing: `beginLoading` waits before showing anything,
/// so a warm cache never flashes a skeleton, and once shown it stays for a minimum so
/// it can't strobe either. Callers just bracket their request.
final class SkeletonGridView: UIView {

    /// Mirrors whichever layout it stands in for. A grid skeleton over a carousel is
    /// worse than none — it promises a shape the content won't arrive in.
    enum Style {
        /// Fills the width; posters with a title and metadata bar beneath.
        case grid(columns: Int, rows: Int)
        /// One row of fixed-width posters, overflowing the trailing edge. No captions.
        case carousel(itemWidth: CGFloat)
    }

    /// Long enough that a fast response shows nothing at all.
    private static let appearDelay: TimeInterval = 0.2
    /// Once visible, stay long enough to read as deliberate.
    private static let minimumVisible: TimeInterval = 0.3
    private static let spacing: CGFloat = 10

    private let style: Style
    private var pendingShow: DispatchWorkItem?
    private var shownAt: Date?

    private let content: UIStackView = {
        let stack = UIStackView()
        stack.spacing = SkeletonGridView.spacing
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)

        isUserInteractionEnabled = false
        // Rows and columns overflow the frame deliberately; the caller pins this to the
        // content's bounds and the excess is cut off.
        clipsToBounds = true
        isHidden = true
        alpha = 0

        addSubview(content)
        var leading: CGFloat = 0

        switch style {
        case let .grid(columns, rows):
            content.axis = .vertical
            (0..<rows).forEach { _ in
                content.addArrangedSubview(makeRow(columns: columns, showsCaption: true))
            }

        case let .carousel(itemWidth):
            content.axis = .horizontal
            content.alignment = .top
            // Matches the carousel's own content inset so the two line up exactly.
            leading = 16
            // One more than fits, so the row runs off the edge the way real cells do.
            let count = Int((UIScreen.main.bounds.width / (itemWidth + Self.spacing)).rounded(.up)) + 1
            (0..<count).forEach { _ in
                let cell = makeCell(showsCaption: false)
                cell.widthAnchor.constraint(equalToConstant: itemWidth).isActive = true
                content.addArrangedSubview(cell)
            }
        }

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leading),
            content.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])
        if case .grid = style {
            content.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Loading

    /// Call when a request is actually issued — not when the screen appears, or a
    /// synchronous failure will flash a skeleton before its error message.
    func beginLoading() {
        guard pendingShow == nil, isHidden else { return }
        let work = DispatchWorkItem { [weak self] in self?.reveal() }
        pendingShow = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.appearDelay, execute: work)
    }

    func endLoading() {
        pendingShow?.cancel()
        pendingShow = nil

        guard !isHidden else { return }
        let shownFor = shownAt.map { Date().timeIntervalSince($0) } ?? Self.minimumVisible
        DispatchQueue.main.asyncAfter(
            deadline: .now() + max(0, Self.minimumVisible - shownFor)
        ) { [weak self] in
            self?.conceal()
        }
    }

    private func reveal() {
        pendingShow = nil
        shownAt = Date()
        isHidden = false
        UIView.animate(withDuration: 0.2) { self.alpha = 1 }
        // A slow pulse rather than a shimmer sweep: the palette is near-black and flat,
        // and a travelling highlight would be the loudest thing on screen.
        UIView.animate(
            withDuration: 0.9,
            delay: 0,
            options: [.autoreverse, .repeat, .curveEaseInOut, .allowUserInteraction]
        ) {
            self.content.alpha = 0.45
        }
    }

    private func conceal() {
        UIView.animate(withDuration: 0.25) {
            self.alpha = 0
        } completion: { _ in
            self.isHidden = true
            self.shownAt = nil
            self.content.layer.removeAllAnimations()
            self.content.alpha = 1
        }
    }

    // MARK: - Shapes

    private func makeRow(columns: Int, showsCaption: Bool) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = Self.spacing
        row.distribution = .fillEqually
        row.alignment = .top
        (0..<columns).forEach { _ in row.addArrangedSubview(makeCell(showsCaption: showsCaption)) }
        return row
    }

    private func makeCell(showsCaption: Bool) -> UIView {
        let poster = block(cornerRadius: 12)
        // Matches the real cells: TMDB posters are 2:3.
        poster.heightAnchor.constraint(equalTo: poster.widthAnchor, multiplier: 1.5).isActive = true

        let cell = UIStackView(arrangedSubviews: [poster])
        cell.axis = .vertical
        cell.spacing = 8
        guard showsCaption else { return cell }

        let title = block(cornerRadius: 4)
        title.heightAnchor.constraint(equalToConstant: 13).isActive = true

        let subtitle = block(cornerRadius: 4)
        subtitle.heightAnchor.constraint(equalToConstant: 11).isActive = true
        let subtitleRow = UIView()
        subtitleRow.addSubview(subtitle)
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subtitle.topAnchor.constraint(equalTo: subtitleRow.topAnchor),
            subtitle.bottomAnchor.constraint(equalTo: subtitleRow.bottomAnchor),
            subtitle.leadingAnchor.constraint(equalTo: subtitleRow.leadingAnchor),
            // Short, so it reads as a metadata line rather than a second title.
            subtitle.widthAnchor.constraint(equalTo: subtitleRow.widthAnchor, multiplier: 0.55)
        ])

        cell.addArrangedSubview(title)
        cell.addArrangedSubview(subtitleRow)
        return cell
    }

    private func block(cornerRadius: CGFloat) -> UIView {
        let view = UIView()
        view.backgroundColor = .surface
        view.layer.cornerRadius = cornerRadius
        view.layer.cornerCurve = .continuous
        return view
    }
}
