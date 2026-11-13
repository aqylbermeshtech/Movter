//
//  HomeHeaderView.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import UIKit

final class HomeHeaderView: UIView {

    static let preferredHeight: CGFloat = 44

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Movter"
        label.font = .screenTitle
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
