//
//  ScreenCoachMarksController.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import UIKit

final class ScreenCoachMarksController {
    private enum Constants {
        static let fadeInDuration: TimeInterval = 0.3
        static let fadeOutDuration: TimeInterval = 0.25
        static let anchorRetryDelay: TimeInterval = 0.25
        static let anchorRetryLimit = 6
        static let stepDelay: TimeInterval = 0.05
    }

    private let steps: [CoachMarkStep]
    private let onFinish: () -> Void

    private var index = 0
    private var overlay: CoachMarksOverlayView?

    init(steps: [CoachMarkStep], onFinish: @escaping () -> Void) {
        self.steps = steps
        self.onFinish = onFinish
    }

    func start() {
        guard !steps.isEmpty, let window = Self.activeWindow() else {
            onFinish()
            return
        }

        let overlay = CoachMarksOverlayView(frame: window.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.onNext = { [weak self] in self?.advance() }
        overlay.onSkip = { [weak self] in self?.finish() }
        overlay.alpha = 0
        window.addSubview(overlay)
        self.overlay = overlay

        showStep(0)
        UIView.animate(withDuration: Constants.fadeInDuration) { overlay.alpha = 1 }
    }

    private func advance() {
        index += 1
        if index >= steps.count {
            finish()
        } else {
            showStep(index)
        }
    }

    private func showStep(_ i: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.stepDelay) { [weak self] in
            guard let self else { return }
            self.resolveAndShow(self.steps[i], at: i, attempt: 0)
        }
    }

    private func resolveAndShow(_ step: CoachMarkStep, at i: Int, attempt: Int) {
        guard i == index, let overlay else { return }

        guard let anchorId = step.anchorId else {
            present(step, spotlight: .zero, at: i, on: overlay)
            return
        }

        if let frame = CoachMarkAnchorRegistry.shared.frame(for: anchorId) {
            present(step, spotlight: frame, at: i, on: overlay)
            return
        }

        if attempt < Constants.anchorRetryLimit {
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.anchorRetryDelay) { [weak self] in
                self?.resolveAndShow(step, at: i, attempt: attempt + 1)
            }
            return
        }

        advance()
    }

    private func present(_ step: CoachMarkStep, spotlight: CGRect, at i: Int, on overlay: CoachMarksOverlayView) {
        overlay.update(
            spotlight: spotlight,
            title: step.title,
            message: step.message,
            index: i,
            total: steps.count,
            isLast: i == steps.count - 1
        )
    }

    private func finish() {
        let overlayToDismiss = overlay
        overlay = nil
        UIView.animate(
            withDuration: Constants.fadeOutDuration,
            animations: { overlayToDismiss?.alpha = 0 },
            completion: { _ in overlayToDismiss?.removeFromSuperview() }
        )
        onFinish()
    }

    private static func activeWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
