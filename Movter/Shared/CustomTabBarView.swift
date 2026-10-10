//
//  CustomTabBarView.swift
//  Movter
//
//  Created by Nurtore on 25.08.2026.
//

import UIKit

final class CustomTabBarView: UIView {

    struct Tab {
        let title: String
        let systemImage: String
        let actionSymbol: String
        let actionLabel: String
    }
    static let preferredHeight: CGFloat = 64

    var onTabSelected: ((Int) -> Void)?
    var onActionTapped: (() -> Void)?

    private static let actionButtonSize: CGFloat = preferredHeight
    private static let elementSpacing: CGFloat = 10
    private static let segmentIconTitleSpacing: CGFloat = 3
    private static let capsuleInset: CGFloat = 6

    private let tabs: [Tab]
    private let segmentedControl: UISegmentedControl
    private let actionButton = UIButton(type: .custom)

    private var actionIconViews: [UIImageView] = []

    private var unselectedImages: [UIImage] = []
    private var selectedImages: [UIImage] = []

    init(tabs: [Tab]) {
        self.tabs = tabs
        self.segmentedControl = UISegmentedControl(items: tabs.map { _ in "" })
        super.init(frame: .zero)
        renderSegmentImages()
        setupUI()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (bar: CustomTabBarView, _) in
            bar.renderSegmentImages()
            bar.applySegmentImages()
        }
    }

    private func renderSegmentImages() {
        let idle = UIColor.textPrimary.resolvedColor(with: traitCollection)
        let active = UIColor.onAccent.resolvedColor(with: traitCollection)
        unselectedImages = tabs.map { Self.renderSegmentImage(tab: $0, tint: idle) }
        selectedImages = tabs.map { Self.renderSegmentImage(tab: $0, tint: active) }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        let tabBarGlass = Self.makeGlassView()
        let actionGlass = Self.makeGlassView()

        let containerEffect = UIGlassContainerEffect()
        containerEffect.spacing = Self.elementSpacing
        let container = UIVisualEffectView(effect: containerEffect)
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        container.contentView.addSubview(tabBarGlass)
        container.contentView.addSubview(actionGlass)

        configureSegmentedControl()
        configureActionButton()
        addSubview(segmentedControl)
        addSubview(actionButton)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            tabBarGlass.topAnchor.constraint(equalTo: container.contentView.topAnchor),
            tabBarGlass.bottomAnchor.constraint(equalTo: container.contentView.bottomAnchor),
            tabBarGlass.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor),

            actionGlass.topAnchor.constraint(equalTo: container.contentView.topAnchor),
            actionGlass.bottomAnchor.constraint(equalTo: container.contentView.bottomAnchor),
            actionGlass.leadingAnchor.constraint(equalTo: tabBarGlass.trailingAnchor, constant: Self.elementSpacing),
            actionGlass.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor),
            actionGlass.widthAnchor.constraint(equalToConstant: Self.actionButtonSize),

            // Sized against the glass shapes they sit on, so the two stay aligned.
            segmentedControl.topAnchor.constraint(equalTo: tabBarGlass.topAnchor, constant: Self.capsuleInset),
            segmentedControl.bottomAnchor.constraint(equalTo: tabBarGlass.bottomAnchor, constant: -Self.capsuleInset),
            segmentedControl.leadingAnchor.constraint(equalTo: tabBarGlass.leadingAnchor, constant: Self.capsuleInset),
            segmentedControl.trailingAnchor.constraint(equalTo: tabBarGlass.trailingAnchor, constant: -Self.capsuleInset),

            actionButton.topAnchor.constraint(equalTo: actionGlass.topAnchor),
            actionButton.bottomAnchor.constraint(equalTo: actionGlass.bottomAnchor),
            actionButton.leadingAnchor.constraint(equalTo: actionGlass.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: actionGlass.trailingAnchor)
        ])
    }

    private func configureSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.selectedSegmentTintColor = .accent
        segmentedControl.backgroundColor = .clear
        segmentedControl.apportionsSegmentWidthsByContent = false
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        applySegmentImages()
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }

    private func hideSegmentedControlChrome() {
        DispatchQueue.main.async { [weak self] in
            guard let control = self?.segmentedControl else { return }
            for subview in control.subviews where subview is UIImageView {
                if subview != control.subviews.last {
                    subview.alpha = 0
                }
            }
        }
    }

    private func configureActionButton() {
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        for tab in tabs {
            let iconView = UIImageView(image: UIImage(
                systemName: tab.actionSymbol,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
            ))
            iconView.tintColor = .textPrimary
            iconView.contentMode = .center
            // Taps belong to the button underneath.
            iconView.isUserInteractionEnabled = false
            iconView.translatesAutoresizingMaskIntoConstraints = false
            actionButton.addSubview(iconView)
            NSLayoutConstraint.activate([
                iconView.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor)
            ])
            actionIconViews.append(iconView)
        }
        updateActionIcon(animated: false)
    }

    @objc private func segmentChanged() {
        applySegmentImages()
        updateActionIcon(animated: true)
        onTabSelected?(segmentedControl.selectedSegmentIndex)
    }

    @objc private func actionTapped() {
        onActionTapped?()
    }

    private func applySegmentImages() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        for index in tabs.indices {
            let image = index == selectedIndex ? selectedImages[index] : unselectedImages[index]
            segmentedControl.setImage(image, forSegmentAt: index)
        }
        hideSegmentedControlChrome()
    }

    private func updateActionIcon(animated: Bool) {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        actionButton.accessibilityLabel = tabs[safe: selectedIndex]?.actionLabel

        let apply = {
            for (index, iconView) in self.actionIconViews.enumerated() {
                let isActive = index == selectedIndex
                iconView.alpha = isActive ? 1 : 0
                iconView.transform = isActive ? .identity : CGAffineTransform(scaleX: 0.5, y: 0.5)
            }
        }
        guard animated else {
            apply()
            return
        }
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0,
            options: [.allowUserInteraction],
            animations: apply
        )
    }

    private static func makeGlassView() -> UIVisualEffectView {
        let effect = UIGlassEffect(style: .regular)
        effect.isInteractive = true
        let view = UIVisualEffectView(effect: effect)
        view.cornerConfiguration = .capsule()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private static func renderSegmentImage(tab: Tab, tint: UIColor) -> UIImage {
        let iconConfig = UIImage.SymbolConfiguration(textStyle: .title3)
        let filledName = tab.systemImage.hasSuffix(".fill") ? tab.systemImage : tab.systemImage + ".fill"
        let icon = (UIImage(systemName: filledName, withConfiguration: iconConfig)
            ?? UIImage(systemName: tab.systemImage, withConfiguration: iconConfig))?
            .withTintColor(tint, renderingMode: .alwaysOriginal)

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.tabLabel,
            .foregroundColor: tint
        ]
        let title = tab.title as NSString
        let titleSize = title.size(withAttributes: titleAttributes)
        let iconSize = icon?.size ?? .zero

        let width = ceil(max(iconSize.width, titleSize.width))
        let height = ceil(iconSize.height + segmentIconTitleSpacing + titleSize.height)

        let composed = UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { _ in
            icon?.draw(in: CGRect(
                x: (width - iconSize.width) / 2, y: 0,
                width: iconSize.width, height: iconSize.height
            ))
            title.draw(in: CGRect(
                x: (width - titleSize.width) / 2,
                y: iconSize.height + segmentIconTitleSpacing,
                width: titleSize.width, height: titleSize.height
            ), withAttributes: titleAttributes)
        }
        composed.accessibilityLabel = tab.title
        return composed.withRenderingMode(.alwaysOriginal)
    }
}
