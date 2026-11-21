//
//  SwipeDeckViewController.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import UIKit

final class SwipeDeckViewController: UIViewController {

    private static let maxVisibleCards = 3
    private static let stackScaleStep: CGFloat = 0.06
    private static let stackOffsetStep: CGFloat = 20
    private static let stackAlphaStep: CGFloat = 0.08
    private static let stackTilts: [CGFloat] = [0, -0.05, 0.035]
    private static let cardHorizontalInset: CGFloat = 20
    private static let cardTopInset: CGFloat = 28
    private static let cardBottomInset: CGFloat = 96

    private struct StackAppearance {
        let scale: CGFloat
        let offsetY: CGFloat
        let tilt: CGFloat
        let alpha: CGFloat
    }

    private static func stackAppearance(forIndex index: Int) -> StackAppearance {
        StackAppearance(
            scale: 1 - CGFloat(index) * stackScaleStep,
            offsetY: CGFloat(index) * stackOffsetStep,
            tilt: stackTilts[safe: index] ?? 0,
            alpha: 1 - CGFloat(index) * stackAlphaStep
        )
    }

    private let viewModel: SwipeDeckViewModel
    private var coordinator: SwipeCoordinator?
    private let cardViewFactory: (Media) -> SwipeCardView

    private(set) var cardViews: [SwipeCardView] = []
    private let posterTransition = PosterTransitionController()

    private let cardContainer = UIView()
    private(set) lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .textSecondary
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let passButton = SwipeDeckViewController.makeActionButton(systemImage: "xmark", tint: .destructive)
    private(set) lazy var undoButton = SwipeDeckViewController.makeUndoButton()
    private let likeButton = SwipeDeckViewController.makeActionButton(systemImage: "heart.fill", tint: .accent)

    // MARK: - Placeholder cards

    private(set) lazy var emptyStateCard = SwipeDeckViewController.makePlaceholderCard(
        title: "You're all caught up",
        body: "Check back later for more films to swipe through."
    )

    private lazy var offlineCard = SwipeDeckViewController.makePlaceholderCard(
        title: "You're offline",
        body: "The deck needs a connection. It'll start dealing as soon as you're back."
    )

    private(set) lazy var sessionCompleteBodyLabel: UILabel = {
        let label = UILabel()
        label.text = "You added 0 films to your Watchlist this round."
        label.font = .secondaryBody
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private(set) lazy var dealMoreButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Deal 10 More"
        config.baseBackgroundColor = .accent
        config.baseForegroundColor = .onAccent
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.primaryButton
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(dealMoreTapped), for: .touchUpInside)
        return button
    }()

    private(set) lazy var openWatchlistButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Open Watchlist"
        config.baseBackgroundColor = .hairline
        config.baseForegroundColor = .textPrimary
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 22, bottom: 12, trailing: 22)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.button
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(openWatchlistTapped), for: .touchUpInside)
        return button
    }()

    private(set) lazy var sessionCompleteCard = makeSessionCompleteCard()

    init(
        viewModel: SwipeDeckViewModel,
        coordinator: SwipeCoordinator? = nil,
        cardViewFactory: @escaping (Media) -> SwipeCardView = { SwipeCardView(media: $0) }
    ) {
        self.viewModel = viewModel
        self.cardViewFactory = cardViewFactory
        super.init(nibName: nil, bundle: nil)
        let actualCoordinator = coordinator ?? DefaultSwipeCoordinator(viewController: self)
        self.coordinator = actualCoordinator
        if let defaultCoord = actualCoordinator as? DefaultSwipeCoordinator, defaultCoord.viewController == nil {
            defaultCoord.viewController = self
        }
    }

    convenience init(watchlistStore: WatchlistStoring, seenFilmsStore: SeenFilmsStoring) {
        let viewModel = SwipeDeckViewModel(watchlistStore: watchlistStore, seenFilmsStore: seenFilmsStore)
        self.init(viewModel: viewModel)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        setupNavigationBar()
        setupLayout()
        bindViewModel()
        loadingIndicator.startAnimating()
        viewModel.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        viewModel.reconcileQueueWithLatestExclusions()
    }

    private func setupNavigationBar() {
        navigationItem.title = "Swipe"
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .canvas
        appearance.titleTextAttributes = [.foregroundColor: UIColor.textPrimary]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .textPrimary
    }

    private func setupLayout() {
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardContainer)
        view.addSubview(loadingIndicator)
        cardContainer.addSubview(emptyStateCard)
        cardContainer.addSubview(sessionCompleteCard)
        cardContainer.addSubview(offlineCard)

        let buttonStack = UIStackView(arrangedSubviews: [passButton, undoButton, likeButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 24
        buttonStack.alignment = .center
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)

        passButton.addTarget(self, action: #selector(passTapped), for: .touchUpInside)
        undoButton.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        undoButton.isEnabled = viewModel.canUndo
        undoButton.isHidden = viewModel.isSessionComplete && !viewModel.canUndo

        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Self.cardTopInset),
            cardContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Self.cardHorizontalInset),
            cardContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Self.cardHorizontalInset),
            cardContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Self.cardBottomInset),

            loadingIndicator.centerXAnchor.constraint(equalTo: cardContainer.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),

            buttonStack.topAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: 20),
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        for card in [emptyStateCard, sessionCompleteCard, offlineCard] {
            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: cardContainer.topAnchor),
                card.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
                card.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
                card.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor)
            ])
        }
    }

    @objc private func connectivityChanged() {
        viewModel.connectivityDidChange()
        updateEmptyState()
    }

    private func bindViewModel() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(connectivityChanged),
            name: NetworkMonitor.connectivityDidChangeNotification, object: nil
        )
        viewModel.onQueueChange = { [weak self] in self?.syncCardsFromQueue() }
        viewModel.onError = { [weak self] message in
            self?.loadingIndicator.stopAnimating()
            self?.updateEmptyState()
            self?.presentError(message)
        }
    }

    // MARK: - Stack management

    func syncCardsFromQueue() {
        if cardViews.isEmpty && viewModel.isLoading && !viewModel.isSessionComplete {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }

        let target = viewModel.peek(Self.maxVisibleCards)
        let targetIDs = Set(target.map(\.id))

        var retainedByID: [Int: SwipeCardView] = [:]
        for card in cardViews {
            if !card.hasCommitted, targetIDs.contains(card.media.id), retainedByID[card.media.id] == nil {
                retainedByID[card.media.id] = card
            } else {
                card.onSwiped = nil
                card.removeFromSuperview()
            }
        }

        var updatedCards: [SwipeCardView] = []
        for media in target {
            if let existing = retainedByID.removeValue(forKey: media.id) {
                updatedCards.append(existing)
            } else {
                updatedCards.append(makeCardView(for: media))
            }
        }

        cardViews = updatedCards
        for card in updatedCards.reversed() {
            if card.superview !== cardContainer {
                cardContainer.addSubview(card)
                NSLayoutConstraint.activate([
                    card.topAnchor.constraint(equalTo: cardContainer.topAnchor),
                    card.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
                    card.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
                    card.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor)
                ])
            } else {
                cardContainer.bringSubviewToFront(card)
            }
        }

        updateStackTransforms(animated: true)
        updateEmptyState()
        let hasCard = !cardViews.isEmpty && !viewModel.isSessionComplete
        passButton.isEnabled = hasCard
        likeButton.isEnabled = hasCard
    }

    private func makeCardView(for media: Media) -> SwipeCardView {
        let card = cardViewFactory(media)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.onSwiped = { [weak self, weak card] direction in
            guard let self, let card, self.cardViews.first === card else { return }
            self.frontCardDidSwipe(direction: direction)
        }
        card.onTapped = { [weak self] media in
            self?.showDetails(for: media)
        }
        card.onDragProgress = { [weak self, weak card] progress in
            guard let self, let card, self.cardViews.first === card else { return }
            self.interpolateBackgroundCards(progress: progress)
        }
        return card
    }

    private func updateStackTransforms(animated: Bool) {
        let updates = {
            for (index, card) in self.cardViews.enumerated() {
                let appearance = Self.stackAppearance(forIndex: index)
                card.transform = CGAffineTransform(scaleX: appearance.scale, y: appearance.scale)
                    .translatedBy(x: 0, y: appearance.offsetY)
                    .rotated(by: appearance.tilt)
                card.alpha = appearance.alpha
                card.isUserInteractionEnabled = (index == 0)
            }
        }
        guard animated else { updates(); return }
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: [.curveEaseOut], animations: updates)
    }

    func interpolateBackgroundCards(progress: CGFloat) {
        guard cardViews.count > 1 else { return }
        let clamped = progress.isFinite ? progress.clamped(to: 0...1) : 0
        for index in 1..<cardViews.count {
            let card = cardViews[index]
            let from = Self.stackAppearance(forIndex: index)
            let to = Self.stackAppearance(forIndex: index - 1)
            let scale = from.scale + (to.scale - from.scale) * clamped
            let offsetY = from.offsetY + (to.offsetY - from.offsetY) * clamped
            let tilt = from.tilt + (to.tilt - from.tilt) * clamped
            let alpha = from.alpha + (to.alpha - from.alpha) * clamped
            card.transform = CGAffineTransform(scaleX: scale, y: scale)
                .translatedBy(x: 0, y: offsetY)
                .rotated(by: tilt)
            card.alpha = alpha
        }
    }

    private func frontCardDidSwipe(direction: SwipeDirection) {
        guard !cardViews.isEmpty else { return }
        let swiped = cardViews.removeFirst()
        swiped.removeFromSuperview()
        viewModel.consumeFrontCard(direction: direction)
    }

    private func updateEmptyState() {
        let sessionComplete = viewModel.isSessionComplete
        let offline = cardViews.isEmpty && viewModel.isOffline && !sessionComplete
        let ranOut = cardViews.isEmpty
            && viewModel.hasLoadedInitialExclusions
            && !viewModel.isLoading
            && !sessionComplete
            && !offline
            && (viewModel.isExhausted || viewModel.queue.isEmpty)
        offlineCard.isHidden = !offline
        sessionCompleteCard.isHidden = !(sessionComplete && cardViews.isEmpty)
        if sessionComplete {
            sessionCompleteBodyLabel.text = "You added \(viewModel.sessionLikesCount) films to your Watchlist this round."
        }
        emptyStateCard.isHidden = !ranOut
        passButton.isHidden = sessionComplete
        likeButton.isHidden = sessionComplete
        undoButton.isEnabled = viewModel.canUndo
        undoButton.isHidden = sessionComplete && !viewModel.canUndo
    }

    // MARK: - Actions

    @objc private func passTapped() {
        guard let card = cardViews.first, !viewModel.isSessionComplete else { return }
        passButton.isEnabled = false
        likeButton.isEnabled = false
        card.performSwipe(direction: .pass)
    }

    @objc private func likeTapped() {
        guard let card = cardViews.first, !viewModel.isSessionComplete else { return }
        passButton.isEnabled = false
        likeButton.isEnabled = false
        card.performSwipe(direction: .like)
    }

    @objc func undoTapped() {
        guard cardViews.first?.hasCommitted != true else { return }
        viewModel.undoLastSwipe()
    }

    @objc func dealMoreTapped() {
        viewModel.startNewSessionBatch()
    }

    @objc func openWatchlistTapped() {
        showWatchlist()
    }

    private func showWatchlist() {
        if let coordinator = coordinator {
            coordinator.showWatchlist()
        } else {
            let watchlistVC = SwipeViewFactory.makeWatchlist(presentation: .watchlist, coordinator: coordinator)
            navigationController?.pushViewController(watchlistVC, animated: true)
        }
    }

    private func showDetails(for media: Media) {
        if let coordinator = coordinator {
            coordinator.showMovieDetails(media: media, from: self)
        } else {
            let detailVC = MediaDetailsViewController(viewModel: MediaDetailsViewModel(media: media))
            posterTransition.push(detailVC, for: media, from: self)
        }
    }

    private func presentError(_ message: String) {
        let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func makeSessionCompleteCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .surface
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.isHidden = true
        card.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(
            systemName: "film.stack",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 52, weight: .semibold)
        ))
        icon.tintColor = .accent
        icon.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = "That's 10 for now"
        titleLabel.font = .movter(size: 20, weight: .bold)
        titleLabel.textColor = .textPrimary
        titleLabel.textAlignment = .center

        let actionsStack = UIStackView(arrangedSubviews: [dealMoreButton, openWatchlistButton])
        actionsStack.axis = .vertical
        actionsStack.spacing = 10
        actionsStack.alignment = .fill

        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, sessionCompleteBodyLabel, actionsStack])
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .center
        stack.setCustomSpacing(16, after: icon)
        stack.setCustomSpacing(24, after: sessionCompleteBodyLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let dealMoreMinWidth = dealMoreButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
        dealMoreMinWidth.priority = UILayoutPriority(999)

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            dealMoreMinWidth,
            actionsStack.widthAnchor.constraint(lessThanOrEqualTo: stack.widthAnchor),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -32)
        ])
        return card
    }

    private static func makePlaceholderCard(title: String, body: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .surface
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.isHidden = true
        card.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UpsetRobotIllustration.image(pointSize: 72, color: .textSecondary))
        icon.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .movter(size: 20, weight: .bold)
        titleLabel.textColor = .textPrimary
        titleLabel.textAlignment = .center

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = .secondaryBody
        bodyLabel.textColor = .textSecondary
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .center
        stack.setCustomSpacing(16, after: icon)
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -32)
        ])
        return card
    }

    private static func makeActionButton(systemImage: String, tint: UIColor) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        )
        config.baseBackgroundColor = .surface
        config.baseForegroundColor = tint
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        return UIButton(configuration: config)
    }

    private static func makeUndoButton() -> UIButton {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(
            systemName: "arrow.uturn.backward",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        )
        config.baseBackgroundColor = .surface
        config.baseForegroundColor = .textPrimary
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        let button = UIButton(configuration: config)
        button.accessibilityLabel = "Undo last swipe"
        button.isEnabled = false
        return button
    }
}

// MARK: - Poster transition

extension SwipeDeckViewController: PosterTransitionSource {
    func transitionPoster(forMediaID id: Int) -> PosterTransitionAnchor? {
        guard let top = cardViews.first, top.media.id == id else { return nil }
        return top.posterAnchor
    }
}
