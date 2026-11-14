//
//  TicketViewController.swift
//  Movter
//
//  Created by Nurtore on 02.09.2026.
//

import CoreText
import SwiftUI
import UIKit

enum TicketFonts {
    private static let registerOnce: Void = {
        for name in ["Adamina-Regular", "SpaceMono-Regular", "SpaceMono-Bold"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Resources/Fonts") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }()

    static func adamina(size: CGFloat) -> Font {
        _ = registerOnce
        return .custom("Adamina-Regular", size: size)
    }

    static func monoRegular(size: CGFloat) -> Font {
        _ = registerOnce
        return .custom("SpaceMono-Regular", size: size)
    }

    static func monoBold(size: CGFloat) -> Font {
        _ = registerOnce
        return .custom("SpaceMono-Bold", size: size)
    }
}

final class TicketViewController: UIHostingController<TicketView> {

    init(review: Review) {
        super.init(rootView: TicketView(review: review))
        title = "Ticket"
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }
}

// MARK: - SwiftUI Screen

struct TicketView: View {
    let review: Review

    @Environment(\.colorScheme) private var colorScheme
    @State private var posterImage: UIImage?
    @State private var logoImage: UIImage?
    @State private var renderedTicket: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Text("ADDED TO YOUR COLLECTION")
                        .font(Font(UIFont.microLabel))
                        .tracking(1.4)
                        .foregroundStyle(Color(uiColor: .textSecondary))

                    TicketStubView(
                        review: review,
                        posterImage: posterImage,
                        logoImage: logoImage
                    )

                    shareControl
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
        .background(Color(uiColor: .canvas).ignoresSafeArea())
        .task(id: review.id) {
            await loadArtwork()
        }
        .onChange(of: colorScheme) { _, _ in
            renderForShare()
        }
    }

    @ViewBuilder
    private var shareControl: some View {
        if let image = renderedTicket {
            ShareLink(
                item: Image(uiImage: image),
                preview: SharePreview(review.filmTitle, image: Image(uiImage: image))
            ) {
                shareLabel
            }
        } else {
            Button(action: renderForShare) {
                shareLabel
            }
            .disabled(true)
            .opacity(0.6)
        }
    }

    private var shareLabel: some View {
        Text("Share Ticket")
            .font(Font(UIFont.primaryButton))
            .foregroundStyle(Color(uiColor: .onAccent))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(Color(uiColor: .accent), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @MainActor
    private func loadArtwork() async {
        async let loadedPoster = loadImage(from: review.posterURL)
        async let loadedLogo = loadTitleLogo()

        posterImage = await loadedPoster
        logoImage = await loadedLogo
        renderForShare()
    }

    private func loadTitleLogo() async -> UIImage? {
        guard let tmdbID = review.tmdbID else { return nil }
        let artwork = await TMDBService.shared.fetchHeroArtwork(for: tmdbID, type: .movie)
        guard !Task.isCancelled,
              let logoPath = artwork.logoPath,
              let logoURL = TMDBImageURL.url(path: logoPath, width: .poster) else {
            return nil
        }
        return await loadImage(from: logoURL)
    }

    private func loadImage(from url: URL?) async -> UIImage? {
        guard let url else { return nil }
        return await withCheckedContinuation { continuation in
            ImageLoader.load(url: url) { image in
                continuation.resume(returning: image)
            }
        }
    }

    @MainActor
    private func renderForShare() {
        let stub = TicketStubView(
            review: review,
            posterImage: posterImage,
            logoImage: logoImage
        )
        .environment(\.colorScheme, colorScheme)
        .frame(width: 390)
        .padding(12)
        .background(Color(uiColor: .canvas))

        let renderer = ImageRenderer(content: stub)
        renderer.scale = UIScreen.main.scale
        renderedTicket = renderer.uiImage
    }
}

// MARK: - Horizontal Cinema Ticket Stub

struct TicketStubView: View {
    let review: Review
    let posterImage: UIImage?
    let logoImage: UIImage?

    @Environment(\.colorScheme) private var colorScheme

    private static let mainFraction: CGFloat = 0.70

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    var body: some View {
        GeometryReader { geo in
            let mainWidth = geo.size.width * Self.mainFraction
            let stubWidth = geo.size.width - mainWidth

            ZStack(alignment: .topLeading) {
                Color.ticketBackground

                TicketOrnamentCanvas(
                    mainFraction: Self.mainFraction,
                    perforationColor: .ticketPerforation
                )

                HStack(spacing: 0) {
                    mainSection
                        .frame(width: mainWidth, height: geo.size.height)

                    stubSection
                        .frame(width: stubWidth, height: geo.size.height)
                }
            }
            .clipShape(TicketShape(mainFraction: Self.mainFraction))
        }
        .aspectRatio(1.0 / 0.42, contentMode: .fit)
    }

    private var mainSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("CINEMA")
                        .font(TicketFonts.adamina(size: 19))
                        .tracking(1.2)
                        .foregroundStyle(Color.ticketHeader)
                        .lineLimit(1)

                    Text("TICKET")
                        .font(TicketFonts.monoBold(size: 9.5))
                        .tracking(2.0)
                        .foregroundStyle(Color.ticketMutedText)
                }
                .fixedSize()

                Spacer(minLength: 4)

                if let logoImage {
                    Image(uiImage: logoImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 118, maxHeight: 44, alignment: .trailing)
                        .shadow(
                            color: .black.opacity(colorScheme == .dark ? 0.55 : 0),
                            radius: 2, x: 0, y: 1
                        )
                } else {
                    Text(review.filmTitle.uppercased())
                        .font(TicketFonts.adamina(size: 13))
                        .foregroundStyle(Color.ticketPrimaryText)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                }
            }

            DashedDivider(color: .ticketDivider)

            VStack(alignment: .leading, spacing: 4) {
                if let year = review.filmYear, !year.isEmpty {
                    Text(year)
                        .font(TicketFonts.monoBold(size: 11))
                        .foregroundStyle(Color.ticketPrimaryText)
                }

                HStack(alignment: .center) {
                    Text("Rated \(Self.dateFormatter.string(from: review.createdAt))")
                        .font(TicketFonts.monoRegular(size: 10))
                        .foregroundStyle(Color.ticketMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 8)

                    Text("\(review.score)/10")
                        .font(TicketFonts.monoBold(size: 11))
                        .foregroundStyle(Color.ticketScore)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.ticketPanel, in: RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var stubSection: some View {
        ZStack {
            posterCard
                .overlay(alignment: .topLeading) {
                    TapeStripView()
                        .rotationEffect(.degrees(-32))
                        .offset(x: -10, y: -2)
                }
                .overlay(alignment: .bottomTrailing) {
                    TapeStripView()
                        .rotationEffect(.degrees(-30))
                        .offset(x: 10, y: 2)
                }
        }
    }

    private var posterCard: some View {
        Group {
            if let posterImage {
                Image(uiImage: posterImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.ticketPanel
                    Image(systemName: "film")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.ticketMutedText)
                }
            }
        }
        .frame(width: 80, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(Color.ticketPosterBorder, lineWidth: 1.5)
        )
    }
}

// MARK: - 90s Tape Strip

private struct TapeStripView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(Color.ticketTapeFill)
            .overlay(
                RoundedRectangle(cornerRadius: 1.5)
                    .stroke(Color.ticketTapeStroke, lineWidth: 0.5)
            )
            .frame(width: 32, height: 11)
            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Ticket Shape & Ornament Canvas

private struct TicketShape: Shape {
    let mainFraction: CGFloat

    private let cornerCut: CGFloat = 11
    private let tearNotchRadius: CGFloat = 8
    private let edgeScallopRadius: CGFloat = 3.2
    private let edgeScallopPitch: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let c = cornerCut
        let tearX = w * mainFraction

        var path = Path()
        path.move(to: CGPoint(x: c, y: 0))
        path.addLine(to: CGPoint(x: w - c, y: 0))
        path.addArc(center: CGPoint(x: w, y: 0), radius: c, startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
        path.addLine(to: CGPoint(x: w, y: h - c))
        path.addArc(center: CGPoint(x: w, y: h), radius: c, startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)
        path.addLine(to: CGPoint(x: c, y: h))
        path.addArc(center: CGPoint(x: 0, y: h), radius: c, startAngle: .degrees(0), endAngle: .degrees(270), clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: c))
        path.addArc(center: CGPoint(x: 0, y: 0), radius: c, startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
        path.closeSubpath()

        var cutouts = Path()
        let r = tearNotchRadius
        cutouts.addEllipse(in: CGRect(x: tearX - r, y: -r, width: r * 2, height: r * 2))
        cutouts.addEllipse(in: CGRect(x: tearX - r, y: h - r, width: r * 2, height: r * 2))

        let sr = edgeScallopRadius
        let startY = c + edgeScallopPitch * 0.7
        let endY = h - c - edgeScallopPitch * 0.7
        var y = startY
        while y <= endY {
            cutouts.addEllipse(in: CGRect(x: -sr, y: y - sr, width: sr * 2, height: sr * 2))
            cutouts.addEllipse(in: CGRect(x: w - sr, y: y - sr, width: sr * 2, height: sr * 2))
            y += edgeScallopPitch
        }

        return path.subtracting(cutouts)
    }
}

private struct DashedDivider: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height / 2))
            path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
        .frame(height: 1)
    }
}

private struct TicketOrnamentCanvas: View {
    let mainFraction: CGFloat
    let perforationColor: Color

    var body: some View {
        Canvas { context, size in
            let tearX = size.width * mainFraction

            var perforation = Path()
            perforation.move(to: CGPoint(x: tearX, y: 12))
            perforation.addLine(to: CGPoint(x: tearX, y: size.height - 12))
            context.stroke(
                perforation,
                with: .color(perforationColor),
                style: StrokeStyle(lineWidth: 1, dash: [3, 3])
            )
        }
        .allowsHitTesting(false)
    }
}
