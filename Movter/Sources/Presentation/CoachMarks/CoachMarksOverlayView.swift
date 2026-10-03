//
//  CoachMarksOverlayView.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import UIKit
import SwiftUI
//import MentorUI

final class CoachMarksOverlayView: UIView {
    var onNext: (() -> Void)?
    var onSkip: (() -> Void)?

    private let dimView = UIView()
    private let maskLayer = CAShapeLayer()
    private let card = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let counterLabel = UILabel()
    private let skipButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)

    private var spotlight: CGRect = .zero
    private var cardBottomConstraint: NSLayoutConstraint?
    private var cardTopConstraint: NSLayoutConstraint?
    private var cardCenterYConstraint: NSLayoutConstraint?

    private enum Layout {
        static let spotlightPadding: CGFloat = 3
        static let cornerRadius: CGFloat = 14
        static let cardCorner: CGFloat = 20
        static let cardInset: CGFloat = 20
        static let gap: CGFloat = 16
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        maskLayer.fillRule = .evenOdd
        dimView.layer.mask = maskLayer

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        dimView.addGestureRecognizer(tap)

        card.backgroundColor = UIColor(SwiftUI.Color.background)
        card.layer.cornerRadius = Layout.cardCorner
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.15
        card.layer.shadowRadius = 20
        card.layer.shadowOffset = CGSize(width: 0, height: 8)
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        counterLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        counterLabel.textColor = UIColor(SwiftUI.Color.buttonPrimary)

        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = UIColor(SwiftUI.Color.textPrimary)
        titleLabel.numberOfLines = 0

        messageLabel.font = .systemFont(ofSize: 15, weight: .regular)
        messageLabel.textColor = UIColor(SwiftUI.Color.textSecondary)
        messageLabel.numberOfLines = 0

        skipButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        skipButton.setTitleColor(UIColor(SwiftUI.Color.textSecondary), for: .normal)
        skipButton.addTarget(self, action: #selector(handleSkip), for: .touchUpInside)

        var nextConfig = UIButton.Configuration.filled()
        nextConfig.baseBackgroundColor = UIColor(SwiftUI.Color.buttonPrimary)
        nextConfig.baseForegroundColor = .white
        nextConfig.cornerStyle = .fixed
        nextConfig.background.cornerRadius = 12
        nextConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        nextButton.configuration = nextConfig
        nextButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)

        let buttonsRow = UIStackView(arrangedSubviews: [skipButton, UIView(), nextButton])
        buttonsRow.axis = .horizontal
        buttonsRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [counterLabel, titleLabel, messageLabel, buttonsRow])
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(16, after: messageLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: Layout.cardInset),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -Layout.cardInset),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Layout.cardInset),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Layout.cardInset)
        ])

        card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.cardInset).isActive = true
        card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.cardInset).isActive = true

        cardBottomConstraint = card.bottomAnchor.constraint(equalTo: topAnchor)
        cardTopConstraint = card.topAnchor.constraint(equalTo: topAnchor)
        cardCenterYConstraint = card.centerYAnchor.constraint(equalTo: centerYAnchor)
    }

    func update(spotlight: CGRect, title: String, message: String, index: Int, total: Int, isLast: Bool) {
        let isFirstStep = counterLabel.text == nil
        self.spotlight = spotlight
        counterLabel.text = "\(index + 1) / \(total)"
        titleLabel.text = title
        messageLabel.text = message
        skipButton.setTitle(skipTitle, for: .normal)
        nextButton.setTitle(isLast ? doneTitle : nextTitle, for: .normal)
        skipButton.isHidden = isLast
        setNeedsLayout()
        layoutIfNeeded()
        applySpotlightMask()
        positionCard()

        guard !isFirstStep else {
            layoutIfNeeded()
            return
        }
        card.alpha = 0.25
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.card.alpha = 1
            self.layoutIfNeeded()
        }
    }

    private func positionCard() {
        cardBottomConstraint?.isActive = false
        cardTopConstraint?.isActive = false
        cardCenterYConstraint?.isActive = false

        if spotlight == .zero {
            cardCenterYConstraint?.isActive = true
            return
        }

        // Тултип над подсветкой если снизу есть место (табы внизу), иначе под ней.
        let cardHeight = card.systemLayoutSizeFitting(
            CGSize(width: bounds.width - Layout.cardInset * 2, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        let spaceAbove = spotlight.minY
        if spaceAbove > cardHeight + Layout.gap + safeAreaInsets.top {
            cardBottomConstraint = card.bottomAnchor.constraint(equalTo: topAnchor, constant: spotlight.minY - Layout.gap)
            cardBottomConstraint?.isActive = true
        } else {
            cardTopConstraint = card.topAnchor.constraint(equalTo: topAnchor, constant: spotlight.maxY + Layout.gap)
            cardTopConstraint?.isActive = true
        }
    }

    private func applySpotlightMask() {
        let path = UIBezierPath(rect: dimView.bounds)
        if spotlight != .zero {
            let hole = spotlight.insetBy(dx: -Layout.spotlightPadding, dy: -Layout.spotlightPadding)
            path.append(UIBezierPath(roundedRect: hole, cornerRadius: Layout.cornerRadius))
        }
        maskLayer.path = path.cgPath
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applySpotlightMask()
    }

    @objc private func handleBackgroundTap() { onNext?() }
    @objc private func handleNext() { onNext?() }
    @objc private func handleSkip() { onSkip?() }

    private var nextTitle: String { CoachMarksContent.Copy.resolve(LanguageManager.shared.currentLanguage.code).next }
    private var doneTitle: String { CoachMarksContent.Copy.resolve(LanguageManager.shared.currentLanguage.code).done }
    private var skipTitle: String { CoachMarksContent.Copy.resolve(LanguageManager.shared.currentLanguage.code).skip }
}
