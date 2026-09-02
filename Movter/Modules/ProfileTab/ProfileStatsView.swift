//
//  ProfileStatsView.swift
//  Movter
//
//  Created by Nurtore on 02.09.2026.
//

import UIKit

/// What the account amounts to, in three numbers: films seen, films written about, and
/// films still waiting. Sits where the avatar used to — a profile in this app is what
/// you have watched, not what you look like.
final class ProfileStatsView: UIView {

    private let watchedColumn = ColumnView(caption: "WATCHED")
    private let reviewsColumn = ColumnView(caption: "REVIEWS")
    private let watchlistColumn = ColumnView(caption: "WATCHLIST")

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .surface
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous

        let stack = UIStackView(arrangedSubviews: [
            watchedColumn, Self.makeDivider(), reviewsColumn, Self.makeDivider(), watchlistColumn
        ])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        // The columns share the width; the two hairlines take only what they need.
        watchedColumn.widthAnchor.constraint(equalTo: reviewsColumn.widthAnchor).isActive = true
        reviewsColumn.widthAnchor.constraint(equalTo: watchlistColumn.widthAnchor).isActive = true

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(watched: Int, reviews: Int, watchlist: Int) {
        watchedColumn.value = watched
        reviewsColumn.value = reviews
        watchlistColumn.value = watchlist
    }

    private static func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .hairline
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.widthAnchor.constraint(equalToConstant: 1),
            divider.heightAnchor.constraint(equalToConstant: 28)
        ])
        return divider
    }

    /// One number over its caption.
    private final class ColumnView: UIView {

        var value: Int = 0 {
            didSet { valueLabel.text = "\(value)" }
        }

        private let valueLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 22, weight: .bold)
            label.textColor = .textPrimary
            label.textAlignment = .center
            return label
        }()

        private let captionLabel: UILabel

        init(caption: String) {
            captionLabel = UILabel()
            captionLabel.attributedText = NSAttributedString(
                string: caption,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                    .foregroundColor: UIColor.textSecondary,
                    .kern: 0.8
                ]
            )
            captionLabel.textAlignment = .center
            super.init(frame: .zero)

            let stack = UIStackView(arrangedSubviews: [valueLabel, captionLabel])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 2
            stack.translatesAutoresizingMaskIntoConstraints = false
            addSubview(stack)

            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: topAnchor),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}
