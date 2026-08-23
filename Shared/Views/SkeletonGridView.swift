//
//  SkeletonGridView.swift
//  Movter
//
//  Created by Nurtore on 22.08.2026.
//

import UIKit

/// Placeholder shapes for a poster grid that hasn't loaded yet.
///
/// Timing matters more than the drawing: `beginLoading` waits before showing anything,
/// so a warm cache never flashes a skeleton, and once shown it stays for a minimum so
/// it can't strobe either. Callers just bracket their request.
final class SkeletonGridView: UIView {

    /// Long enough that a fast response shows nothing at all.
    private static let appearDelay: TimeInterval = 0.2
    /// Once visible, stay long enough to read as deliberate.
    private static let minimumVisible: TimeInterval = 0.3

    private let columns: Int
    private let rows: Int
    private var pendingShow: DispatchWorkItem?
    private var shownAt: Date?

    private let content: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    init(columns: Int = 3, rows: Int = 4) {
        self.columns = columns
        self.rows = rows
        super.init(frame: .zero)

        isUserInteractionEnabled = false
        // Rows overflow the frame deliberately: the caller pins this to the grid's
        // bounds and the extra rows are simply cut off at the bottom.
        clipsToBounds = true
        isHidden = true
        alpha = 0

        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        (0..<rows).forEach { _ in content.addArrangedSubview(makeRow()) }
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
        let remaining = max(0, Self.minimumVisible - shownFor)
        DispatchQueue.main.asyncAfter(deadline: .now() + remaining) { [weak self] in
            self?.conceal()
        }
    }

    private func reveal() {
        pendingShow = nil
        shownAt = Date()
        isHidden = false
        UIView.animate(withDuration: 0.2) { self.alpha = 1 }
        // A slow pulse rather than a shimmer sweep: the palette is near-black and
        // deliberately flat, and a travelling highlight would be the loudest thing
        // on screen. Static blocks alone read as empty cells rather than as work.
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

    private func makeRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 10
        row.distribution = .fillEqually
        row.alignment = .top
        (0..<columns).forEach { _ in row.addArrangedSubview(makeCell()) }
        return row
    }

    private func makeCell() -> UIView {
        let poster = block(cornerRadius: 12)
        // Matches the real cells: poster is 1.5x its own width.
        poster.heightAnchor.constraint(equalTo: poster.widthAnchor, multiplier: 1.5).isActive = true

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
            // Short, so the block reads as a metadata line rather than a second title.
            subtitle.widthAnchor.constraint(equalTo: subtitleRow.widthAnchor, multiplier: 0.55)
        ])

        let cell = UIStackView(arrangedSubviews: [poster, title, subtitleRow])
        cell.axis = .vertical
        cell.spacing = 8
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
