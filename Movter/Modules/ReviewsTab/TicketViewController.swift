//
//  TicketViewController.swift
//  Movter
//
//  Created by Nurtore on 02.09.2026.
//

import UIKit

final class TicketViewController: UIViewController {

    private let review: Review

    init(review: Review) {
        self.review = review
        super.init(nibName: nil, bundle: nil)
        title = "Ticket"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: "ADDED TO YOUR COLLECTION",
            attributes: [
                .font: UIFont.microLabel,
                .foregroundColor: UIColor.textSecondary,
                .kern: 1.4
            ]
        )
        label.textAlignment = .center
        return label
    }()

    private let ticketView = TicketStubView()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [captionLabel, ticketView, shareButton])
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var lastFittedSize: CGSize = .zero

    private lazy var shareButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        config.baseBackgroundColor = .accent
        config.baseForegroundColor = .onAccent
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        config.attributedTitle = AttributedString(
            "Share Ticket",
            attributes: AttributeContainer([.font: UIFont.primaryButton])
        )
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneTapped)
        )
        setupUI()
        ticketView.configure(with: review)
    }

    private func setupUI() {
        view.addSubview(scrollView)

        let stack = contentStack
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fitArtworkToScreen()
        centreContentIfItFits()
    }

    private func centreContentIfItFits() {
        let visible = scrollView.bounds.height - scrollView.safeAreaInsets.bottom
        let top = max(0, (visible - scrollView.contentSize.height) / 2)
        guard abs(scrollView.contentInset.top - top) > 0.5 else { return }
        scrollView.contentInset.top = top
    }

    private func fitArtworkToScreen() {
        let size = scrollView.bounds.size
        guard size.width > 0, size.height > 0, size != lastFittedSize else { return }
        lastFittedSize = size

        let contentWidth = size.width - 32

        ticketView.artworkHeight = 0
        contentStack.setNeedsLayout()
        contentStack.layoutIfNeeded()
        let withoutArtwork = contentStack.systemLayoutSizeFitting(
            CGSize(width: contentWidth, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        let visible = size.height - scrollView.safeAreaInsets.bottom
        let spare = visible - Self.stackVerticalPadding - withoutArtwork
        let natural = contentWidth * review.ticketArtworkAspect
        ticketView.artworkHeight = max(0, min(spare, natural))
    }
    private static let stackVerticalPadding: CGFloat = 20 + 24

    @objc private func doneTapped() {
        dismiss(animated: true)
    }
}

// MARK: - The stub

final class TicketStubView: UIView {

    private static let cornerRadius: CGFloat = 20
    private static let notchRadius: CGFloat = 11
    private static let inset: CGFloat = 20

    private var posterURL: URL?

    private let artworkView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleToFill
        iv.clipsToBounds = true
        iv.backgroundColor = .hairline
        iv.tintColor = .textSecondary
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private var artworkHeightConstraint: NSLayoutConstraint!

    var artworkHeight: CGFloat {
        get { artworkHeightConstraint.constant }
        set { artworkHeightConstraint.constant = max(0, newValue) }
    }

    private let stubLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: "TICKET STUB",
            attributes: [
                .font: UIFont.movter(size: 11, weight: .bold),
                .foregroundColor: UIColor.textSecondary,
                .kern: 1.2
            ]
        )
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .cardTitle
        label.textColor = .textPrimary
        label.numberOfLines = 2
        return label
    }()

    private let watchedLabel: UILabel = {
        let label = UILabel()
        label.font = .caption
        label.textColor = .textSecondary
        return label
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .emphasized
        label.textAlignment = .right
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let noteLabel: UILabel = {
        let label = UILabel()
        label.font = .secondaryBody
        label.textColor = .textPrimary
        label.numberOfLines = 0
        return label
    }()

    private let ruleView: UIView = {
        let view = UIView()
        view.backgroundColor = .hairline
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let barcodeView = BarcodeView()

    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .textSecondary
        label.textAlignment = .right
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let perforationLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineDashPattern = [4, 4]
        layer.lineWidth = 1
        layer.fillColor = nil
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .surface
        layer.addSublayer(perforationLayer)

        let metaRow = UIStackView(arrangedSubviews: [watchedLabel, scoreLabel])
        metaRow.axis = .horizontal
        metaRow.alignment = .firstBaseline
        metaRow.spacing = 12

        let footerRow = UIStackView(arrangedSubviews: [barcodeView, numberLabel])
        footerRow.axis = .horizontal
        footerRow.alignment = .center
        footerRow.spacing = 12

        let stub = UIStackView(arrangedSubviews: [
            stubLabel, titleLabel, metaRow, noteLabel, ruleView, footerRow
        ])
        stub.axis = .vertical
        stub.spacing = 12
        stub.setCustomSpacing(6, after: stubLabel)
        stub.setCustomSpacing(16, after: noteLabel)
        stub.setCustomSpacing(14, after: ruleView)
        stub.translatesAutoresizingMaskIntoConstraints = false

        addSubview(artworkView)
        addSubview(stub)

        artworkHeightConstraint = artworkView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            // Edge to edge: the card's own mask rounds the top corners for it.
            artworkView.topAnchor.constraint(equalTo: topAnchor),
            artworkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            artworkView.trailingAnchor.constraint(equalTo: trailingAnchor),
            artworkHeightConstraint,

            stub.topAnchor.constraint(equalTo: artworkView.bottomAnchor, constant: Self.inset),
            stub.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.inset),
            stub.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.inset),
            stub.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.inset),

            ruleView.heightAnchor.constraint(equalToConstant: 1),
            barcodeView.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let tearY = artworkView.frame.maxY
        applyMask(tearY: tearY)
        drawPerforation(at: tearY)
        updateArtworkCrop()
    }
    
    private func updateArtworkCrop() {
        guard let image = artworkView.image, isShowingArtwork else {
            artworkView.layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            return
        }
        let size = image.size
        let box = artworkView.bounds.size
        guard size.width > 0, size.height > 0, box.width > 0, box.height > 0 else { return }

        let scale = box.width / size.width
        let visible = min(1, (box.height / scale) / size.height)
        artworkView.layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: visible)
    }

    private var isShowingArtwork = false

    private func applyMask(tearY: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: Self.cornerRadius)
        let radius = Self.notchRadius
        for centerX in [CGFloat(0), bounds.width] {
            path.append(UIBezierPath(ovalIn: CGRect(
                x: centerX - radius, y: tearY - radius, width: radius * 2, height: radius * 2
            )))
        }
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        mask.fillRule = .evenOdd
        layer.mask = mask
    }

    private func drawPerforation(at tearY: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: Self.notchRadius + 6, y: tearY))
        path.addLine(to: CGPoint(x: bounds.width - Self.notchRadius - 6, y: tearY))
        perforationLayer.path = path.cgPath
        perforationLayer.strokeColor = UIColor.canvas.cgColor
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        perforationLayer.strokeColor = UIColor.canvas.cgColor
    }

    func configure(with review: Review) {
        titleLabel.text = review.titleWithYear
        watchedLabel.text = "Watched \(Self.watchedFormatter.string(from: review.createdAt))"
        scoreLabel.attributedText = RatingFormatter.attributedPersonalScore(
            review.score, font: scoreLabel.font
        )
        noteLabel.text = review.reviewText
        noteLabel.isHidden = !review.hasReviewText

        let seed = Self.seed(for: review)
        numberLabel.text = String(format: "NO. %06d", seed % 1_000_000)
        barcodeView.configure(seed: seed)

        posterURL = review.ticketArtworkURL
        guard let url = review.ticketArtworkURL else {
            showArtworkPlaceholder()
            return
        }
        ImageLoader.load(url: url) { [weak self] image in
            guard let self = self, self.posterURL == url else { return }
            guard let image = image else {
                self.showArtworkPlaceholder()
                return
            }
            self.isShowingArtwork = true
            self.artworkView.contentMode = .scaleToFill
            self.artworkView.image = image
            self.setNeedsLayout()
        }
    }

    private func showArtworkPlaceholder() {
        isShowingArtwork = false
        artworkView.layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        artworkView.contentMode = .center
        artworkView.image = UIImage(
            systemName: "film",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        )
    }

    private static func seed(for review: Review) -> UInt32 {
        withUnsafeBytes(of: review.id.uuid) { bytes in
            bytes.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        }
    }

    private static let watchedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

// MARK: - Barcode

final class BarcodeView: UIView {

    private var widths: [CGFloat] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(seed: UInt32) {
        var state = seed | 1
        widths = (0..<28).map { _ in
            state = state &* 1_664_525 &+ 1_013_904_223
            return [CGFloat(1), 1, 2, 3][Int(state >> 16) % 4]
        }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), !widths.isEmpty else { return }
        context.setFillColor(UIColor.textPrimary.cgColor)

        var x: CGFloat = 0
        for width in widths {
            guard x + width <= rect.width else { break }
            context.fill(CGRect(x: x, y: 0, width: width, height: rect.height))
            x += width + 3
        }
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        setNeedsDisplay()
    }
}
