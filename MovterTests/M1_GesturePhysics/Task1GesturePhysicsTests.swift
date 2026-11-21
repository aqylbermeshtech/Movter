import Foundation
import UIKit
import XCTest
@testable import Movter

final class Task1GesturePhysicsTests: XCTestCase {

    // MARK: - Helpers

    private final class MockPanGestureRecognizer: UIPanGestureRecognizer {
        private var mockedState: UIGestureRecognizer.State = .possible
        var mockedTranslation: CGPoint = .zero
        var mockedVelocity: CGPoint = .zero

        override var state: UIGestureRecognizer.State {
            get { mockedState }
            set { mockedState = newValue }
        }

        override func translation(in view: UIView?) -> CGPoint {
            mockedTranslation
        }

        override func velocity(in view: UIView?) -> CGPoint {
            mockedVelocity
        }
    }

    @MainActor
    private func makeCardHost(width: CGFloat = 350, height: CGFloat = 500) -> (container: UIView, card: SwipeCardView) {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 350, height: 500))
        let card = SwipeCardView(media: TestFixtures.makeMedia(id: 1, posterPath: nil), loadRemoteArtwork: false)
        card.frame = CGRect(x: 0, y: 0, width: width, height: height)
        container.addSubview(card)
        container.layoutIfNeeded()
        return (container, card)
    }

    @MainActor
    private func drivePan(
        _ card: SwipeCardView,
        pan: MockPanGestureRecognizer = MockPanGestureRecognizer(),
        steps: [(state: UIGestureRecognizer.State, translation: CGPoint, velocity: CGPoint)]
    ) {
        for step in steps {
            pan.state = step.state
            pan.mockedTranslation = step.translation
            pan.mockedVelocity = step.velocity
            card.handlePan(pan)
        }
    }

    @MainActor
    private func makeDeckController(cardCount: Int) -> SwipeDeckViewController {
        let items = TestFixtures.makeMediaList(count: cardCount)
        let popularRepo = MockPopularMoviesRepository(items: items, isLastPage: true)
        let seenRepo = MockSeenFilmsRepository()
        let watchlistRepo = MockWatchlistRepository()
        let reviewsRepo = MockReviewsRepository()
        let favoritesRepo = MockTopFavoritesRepository()
        let monitor = MockNetworkMonitor(isOnline: true)

        let viewModel = SwipeDeckViewModel(
            fetchDeckUseCase: DefaultFetchPopularSwipeDeckUseCase(popularMoviesRepository: popularRepo),
            swipeCardUseCase: DefaultSwipeCardUseCase(seenFilmsRepository: seenRepo, watchlistRepository: watchlistRepo),
            getExcludedIDsUseCase: DefaultGetExcludedSwipeMediaIDsUseCase(
                seenFilmsRepository: seenRepo,
                watchlistRepository: watchlistRepo,
                reviewsRepository: reviewsRepo,
                topFavoritesRepository: favoritesRepo
            ),
            monitor: monitor
        )
        let vc = SwipeDeckViewController(
            viewModel: viewModel,
            coordinator: MockSwipeCoordinator(),
            cardViewFactory: { SwipeCardView(media: $0, loadRemoteArtwork: false) }
        )
        vc.loadViewIfNeeded()
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()

        let exp = expectation(description: "Deck loaded")
        viewModel.onQueueChange = { [weak vc] in
            vc?.syncCardsFromQueue()
            if (vc?.cardViews.count ?? 0) == min(cardCount, 3) {
                viewModel.onQueueChange = nil
                exp.fulfill()
            }
        }
        viewModel.start()
        wait(for: [exp], timeout: 2.0)
        return vc
    }

    private func assertTransformEqual(
        _ actual: CGAffineTransform,
        _ expected: CGAffineTransform,
        accuracy: CGFloat = 1e-4,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual.a, expected.a, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actual.b, expected.b, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actual.c, expected.c, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actual.d, expected.d, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actual.tx, expected.tx, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actual.ty, expected.ty, accuracy: accuracy, file: file, line: line)
    }

    // MARK: - F2 Tier 1: Velocity & Direction Sign Conflict

    @MainActor
    func test_SwipeCard_RightDragWithPositiveVelocity_CommitsLike() {
        let (_, card) = makeCardHost(width: 350)
        let swipedExp = expectation(description: "onSwiped called")
        var swipedDirection: SwipeDirection?
        card.onSwiped = { direction in
            swipedDirection = direction
            swipedExp.fulfill()
        }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 130, y: 0), CGPoint(x: 300, y: 0)),
            (.ended, CGPoint(x: 130, y: 0), CGPoint(x: 300, y: 0))
        ])

        XCTAssertTrue(card.hasCommitted)
        XCTAssertEqual(card.lastCommittedDirection, .like)
        wait(for: [swipedExp], timeout: 1.5)
        XCTAssertEqual(swipedDirection, .like)
    }

    @MainActor
    func test_SwipeCard_LeftDragWithNegativeVelocity_CommitsPass() {
        let (_, card) = makeCardHost(width: 350)
        let swipedExp = expectation(description: "onSwiped called")
        var swipedDirection: SwipeDirection?
        card.onSwiped = { direction in
            swipedDirection = direction
            swipedExp.fulfill()
        }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: -130, y: 0), CGPoint(x: -300, y: 0)),
            (.ended, CGPoint(x: -130, y: 0), CGPoint(x: -300, y: 0))
        ])

        XCTAssertTrue(card.hasCommitted)
        XCTAssertEqual(card.lastCommittedDirection, .pass)
        wait(for: [swipedExp], timeout: 1.5)
        XCTAssertEqual(swipedDirection, .pass)
    }

    @MainActor
    func test_SwipeCard_SmallRightDragWithStrongLeftFlick_NeverCommitsLike() {
        let (_, card) = makeCardHost(width: 350)
        var swipedDirections: [SwipeDirection] = []
        card.onSwiped = { swipedDirections.append($0) }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 35, y: 0), CGPoint(x: -900, y: 0)),
            (.ended, CGPoint(x: 35, y: 0), CGPoint(x: -900, y: 0))
        ])

        XCTAssertFalse(card.hasCommitted)
        XCTAssertNotEqual(card.lastCommittedDirection, .like)
        XCTAssertTrue(swipedDirections.isEmpty)
    }

    @MainActor
    func test_SwipeCard_FastRightFlickWithPositiveTranslation_CommitsLike() {
        let (_, card) = makeCardHost(width: 350)

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 20, y: 0), CGPoint(x: 900, y: 0)),
            (.ended, CGPoint(x: 20, y: 0), CGPoint(x: 900, y: 0))
        ])

        XCTAssertTrue(card.hasCommitted)
        XCTAssertEqual(card.lastCommittedDirection, .like)
    }

    @MainActor
    func test_SwipeCard_SubThresholdDragWithLowVelocity_SpringsBack() {
        let (_, card) = makeCardHost(width: 350)

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 40, y: 0), CGPoint(x: 100, y: 0)),
            (.ended, CGPoint(x: 40, y: 0), CGPoint(x: 100, y: 0))
        ])

        XCTAssertFalse(card.hasCommitted)
        XCTAssertNil(card.lastCommittedDirection)
    }

    // MARK: - F2 Tier 2: Boundary & Corner Cases

    @MainActor
    func test_SwipeCard_ExactDistanceThreshold_RequiresStrictGreaterThan() {
        let decisionExact = SwipeCardView.evaluatePanRelease(
            translation: CGPoint(x: 350 * SwipeCardView.commitDistanceFraction, y: 0),
            velocity: .zero,
            cardWidth: 350
        )
        XCTAssertEqual(decisionExact, .springBack)

        let (_, card) = makeCardHost(width: 350)
        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.ended, CGPoint(x: 112.1, y: 0), .zero)
        ])
        XCTAssertTrue(card.hasCommitted)
        XCTAssertEqual(card.lastCommittedDirection, .like)
    }

    @MainActor
    func test_SwipeCard_OpposingVelocityBoundary_AtMinus15000VsMinus15001() {
        let (_, committingCard) = makeCardHost(width: 350)
        drivePan(committingCard, steps: [
            (.began, .zero, .zero),
            (.ended, CGPoint(x: 125, y: 0), CGPoint(x: -120, y: 0))
        ])
        XCTAssertTrue(committingCard.hasCommitted)
        XCTAssertEqual(committingCard.lastCommittedDirection, .like)

        let (_, cancellingCard) = makeCardHost(width: 350)
        drivePan(cancellingCard, steps: [
            (.began, .zero, .zero),
            (.ended, CGPoint(x: 125, y: 0), CGPoint(x: -120.01, y: 0))
        ])
        XCTAssertFalse(cancellingCard.hasCommitted)
        XCTAssertNil(cancellingCard.lastCommittedDirection)
    }

    @MainActor
    func test_SwipeCard_ZeroVelocityPastDistanceThreshold_Commits() {
        let (_, card) = makeCardHost(width: 350)
        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.ended, CGPoint(x: -120, y: 0), .zero)
        ])
        XCTAssertTrue(card.hasCommitted)
        XCTAssertEqual(card.lastCommittedDirection, .pass)
    }

    @MainActor
    func test_SwipeCard_ZeroTranslationWithHighVelocity_DoesNotCommit() {
        let (_, card) = makeCardHost(width: 350)
        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.ended, CGPoint(x: 0, y: 10), CGPoint(x: 800, y: 0))
        ])
        XCTAssertFalse(card.hasCommitted)
        XCTAssertNil(card.lastCommittedDirection)
    }

    @MainActor
    func test_SwipeCard_ZeroBoundsWidth_DoesNotCommit() {
        let (_, card) = makeCardHost(width: 0)
        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.ended, CGPoint(x: 20, y: 0), CGPoint(x: 100, y: 0))
        ])
        XCTAssertFalse(card.hasCommitted)
        XCTAssertNil(card.lastCommittedDirection)
    }

    @MainActor
    func test_SwipeCard_MovementBelowTapTolerance_FiresTapAndDoesNotCommit() {
        let (_, card) = makeCardHost(width: 350)
        var tappedMediaID: Int?
        card.onTapped = { tappedMediaID = $0.id }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.ended, CGPoint(x: 5.9, y: -5.9), CGPoint(x: 900, y: 0))
        ])

        XCTAssertEqual(tappedMediaID, 1)
        XCTAssertFalse(card.hasCommitted)
        XCTAssertNil(card.lastCommittedDirection)
    }

    // MARK: - F3 Tier 1: Background Stack Interpolation

    @MainActor
    func test_SwipeCard_DragProgress_EmitsZeroAtRestAndScalesLinearlyToOne() {
        let (_, card) = makeCardHost(width: 350)
        var emitted: [CGFloat] = []
        card.onDragProgress = { emitted.append($0) }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, .zero, .zero),
            (.changed, CGPoint(x: 56, y: 0), .zero),
            (.changed, CGPoint(x: 112, y: 0), .zero)
        ])

        XCTAssertEqual(emitted.count, 3)
        XCTAssertEqual(emitted[0], 0.0, accuracy: 1e-4)
        XCTAssertEqual(emitted[1], 0.5, accuracy: 1e-4)
        XCTAssertEqual(emitted[2], 1.0, accuracy: 1e-4)
    }

    @MainActor
    func test_SwipeDeckVC_InterpolateBackgroundCards_ProgressOne_TransformsIndex1ToFront() {
        let vc = makeDeckController(cardCount: 3)

        vc.interpolateBackgroundCards(progress: 1.0)

        let card1 = vc.cardViews[1]
        assertTransformEqual(card1.transform, .identity)
        XCTAssertEqual(card1.alpha, 1.0, accuracy: 1e-4)
    }

    @MainActor
    func test_SwipeDeckVC_InterpolateBackgroundCards_ProgressOne_TransformsIndex2ToIndex1() {
        let vc = makeDeckController(cardCount: 3)

        vc.interpolateBackgroundCards(progress: 1.0)

        let card2 = vc.cardViews[2]
        let expected = CGAffineTransform(scaleX: 0.94, y: 0.94)
            .translatedBy(x: 0, y: 20)
            .rotated(by: -0.05)
        assertTransformEqual(card2.transform, expected)
        XCTAssertEqual(card2.alpha, 0.92, accuracy: 1e-4)
    }

    @MainActor
    func test_SwipeDeckVC_InterpolateBackgroundCards_PartialProgressHalf_InterpolatesMidpoints() {
        let vc = makeDeckController(cardCount: 3)

        vc.interpolateBackgroundCards(progress: 0.5)

        let card1 = vc.cardViews[1]
        let expected1 = CGAffineTransform(scaleX: 0.97, y: 0.97)
            .translatedBy(x: 0, y: 10)
            .rotated(by: -0.025)
        assertTransformEqual(card1.transform, expected1)
        XCTAssertEqual(card1.alpha, 0.96, accuracy: 1e-4)

        let card2 = vc.cardViews[2]
        let expected2 = CGAffineTransform(scaleX: 0.91, y: 0.91)
            .translatedBy(x: 0, y: 30)
            .rotated(by: -0.0075)
        assertTransformEqual(card2.transform, expected2)
        XCTAssertEqual(card2.alpha, 0.88, accuracy: 1e-4)
    }

    @MainActor
    func test_SwipeCard_SpringBack_InvokesOnDragProgressZero() {
        let (_, card) = makeCardHost(width: 350)
        var emitted: [CGFloat] = []
        card.onDragProgress = { emitted.append($0) }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 60, y: 0), .zero),
            (.ended, CGPoint(x: 60, y: 0), .zero)
        ])

        XCTAssertEqual(emitted.last ?? -1, 0.0, accuracy: 1e-4)
    }

    // MARK: - F3 Tier 2: Boundary & Corner Cases

    @MainActor
    func test_SwipeDeckVC_InterpolateBackgroundCards_NegativeProgress_ClampedToRestingTransforms() {
        let vc = makeDeckController(cardCount: 3)

        vc.interpolateBackgroundCards(progress: -0.5)

        let expected1 = CGAffineTransform(scaleX: 0.94, y: 0.94)
            .translatedBy(x: 0, y: 20)
            .rotated(by: -0.05)
        assertTransformEqual(vc.cardViews[1].transform, expected1)
        XCTAssertEqual(vc.cardViews[1].alpha, 0.92, accuracy: 1e-4)

        let expected2 = CGAffineTransform(scaleX: 0.88, y: 0.88)
            .translatedBy(x: 0, y: 40)
            .rotated(by: 0.035)
        assertTransformEqual(vc.cardViews[2].transform, expected2)
        XCTAssertEqual(vc.cardViews[2].alpha, 0.84, accuracy: 1e-4)
    }

    @MainActor
    func test_SwipeDeckVC_InterpolateBackgroundCards_ProgressAboveOne_ClampedToOne() {
        let vc = makeDeckController(cardCount: 3)

        vc.interpolateBackgroundCards(progress: 2.5)

        assertTransformEqual(vc.cardViews[1].transform, .identity)
        XCTAssertEqual(vc.cardViews[1].alpha, 1.0, accuracy: 1e-4)

        let expected2 = CGAffineTransform(scaleX: 0.94, y: 0.94)
            .translatedBy(x: 0, y: 20)
            .rotated(by: -0.05)
        assertTransformEqual(vc.cardViews[2].transform, expected2)
        XCTAssertEqual(vc.cardViews[2].alpha, 0.92, accuracy: 1e-4)
    }

    @MainActor
    func test_SwipeCard_ZeroBoundsWidth_EmitsZeroDragProgressWithoutNaN() {
        let (_, card) = makeCardHost(width: 0)
        var emitted: [CGFloat] = []
        card.onDragProgress = { emitted.append($0) }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 50, y: 0), .zero)
        ])

        XCTAssertEqual(emitted.count, 1)
        XCTAssertFalse(emitted[0].isNaN)
        XCTAssertEqual(emitted[0], 0.0, accuracy: 1e-4)
    }

    @MainActor
    func test_SwipeDeckVC_InterpolateBackgroundCards_DeckSizes0_1_2_DoNotCrash() {
        let vc0 = makeDeckController(cardCount: 0)
        vc0.interpolateBackgroundCards(progress: 0.5)
        XCTAssertEqual(vc0.cardViews.count, 0)

        let vc1 = makeDeckController(cardCount: 1)
        vc1.interpolateBackgroundCards(progress: 0.5)
        XCTAssertEqual(vc1.cardViews.count, 1)

        let vc2 = makeDeckController(cardCount: 2)
        vc2.interpolateBackgroundCards(progress: 0.5)
        XCTAssertEqual(vc2.cardViews.count, 2)
        XCTAssertEqual(vc2.cardViews[1].alpha, 0.96, accuracy: 1e-4)
    }

    @MainActor
    func test_SwipeDeckVC_InterpolateBackgroundCards_RepeatedProgressOne_IsIdempotent() {
        let vc = makeDeckController(cardCount: 3)

        vc.interpolateBackgroundCards(progress: 1.0)
        let firstTransform1 = vc.cardViews[1].transform
        let firstTransform2 = vc.cardViews[2].transform
        let firstAlpha1 = vc.cardViews[1].alpha
        let firstAlpha2 = vc.cardViews[2].alpha

        vc.interpolateBackgroundCards(progress: 1.0)

        assertTransformEqual(vc.cardViews[1].transform, firstTransform1)
        assertTransformEqual(vc.cardViews[2].transform, firstTransform2)
        XCTAssertEqual(vc.cardViews[1].alpha, firstAlpha1, accuracy: 1e-5)
        XCTAssertEqual(vc.cardViews[2].alpha, firstAlpha2, accuracy: 1e-5)
    }

    // MARK: - F4 Tier 1: Threshold Haptics

    @MainActor
    func test_SwipeCard_CrossingThresholdRightward_FiresHapticOnce() {
        let (_, card) = makeCardHost(width: 350)
        var hapticCount = 0
        card.onThresholdHaptic = { hapticCount += 1 }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 100, y: 0), .zero)
        ])
        XCTAssertEqual(hapticCount, 0)
        XCTAssertFalse(card.didTriggerThresholdHaptic)

        drivePan(card, steps: [
            (.changed, CGPoint(x: 112, y: 0), .zero)
        ])
        XCTAssertEqual(hapticCount, 1)
        XCTAssertTrue(card.didTriggerThresholdHaptic)
    }

    @MainActor
    func test_SwipeCard_StayingAtOrAboveThreshold_DoesNotRefireHaptic() {
        let (_, card) = makeCardHost(width: 350)
        var hapticCount = 0
        card.onThresholdHaptic = { hapticCount += 1 }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 112, y: 0), .zero),
            (.changed, CGPoint(x: 140, y: 0), .zero),
            (.changed, CGPoint(x: 180, y: 0), .zero)
        ])

        XCTAssertEqual(hapticCount, 1)
    }

    @MainActor
    func test_SwipeCard_DroppingBelow085_ResetsAndRefiresOnRecross() {
        let (_, card) = makeCardHost(width: 350)
        var hapticCount = 0
        card.onThresholdHaptic = { hapticCount += 1 }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 112, y: 0), .zero)
        ])
        XCTAssertEqual(hapticCount, 1)

        drivePan(card, steps: [
            (.changed, CGPoint(x: 90, y: 0), .zero)
        ])
        XCTAssertFalse(card.didTriggerThresholdHaptic)

        drivePan(card, steps: [
            (.changed, CGPoint(x: 112, y: 0), .zero)
        ])
        XCTAssertEqual(hapticCount, 2)
    }

    @MainActor
    func test_SwipeCard_GestureEndAndCancel_ResetsDidTriggerThresholdHaptic() {
        let (_, card) = makeCardHost(width: 350)
        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 112, y: 0), .zero)
        ])
        XCTAssertTrue(card.didTriggerThresholdHaptic)

        drivePan(card, steps: [
            (.cancelled, CGPoint(x: 112, y: 0), .zero)
        ])
        XCTAssertFalse(card.didTriggerThresholdHaptic)
    }

    @MainActor
    func test_SwipeCard_CrossingThresholdLeftward_FiresHapticSymmetrically() {
        let (_, card) = makeCardHost(width: 350)
        var hapticCount = 0
        card.onThresholdHaptic = { hapticCount += 1 }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: -112, y: 0), .zero)
        ])

        XCTAssertEqual(hapticCount, 1)
        XCTAssertTrue(card.didTriggerThresholdHaptic)
    }

    // MARK: - F4 Tier 2: Boundary & Corner Cases

    @MainActor
    func test_SwipeCard_JustBelowRightwardThreshold_DoesNotFireHaptic() {
        let (_, card) = makeCardHost(width: 350)
        var hapticCount = 0
        card.onThresholdHaptic = { hapticCount += 1 }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 112 * 0.999, y: 0), .zero)
        ])

        XCTAssertEqual(hapticCount, 0)
        XCTAssertFalse(card.didTriggerThresholdHaptic)
    }

    @MainActor
    func test_SwipeCard_JustBelowLeftwardThreshold_DoesNotFireHaptic() {
        let (_, card) = makeCardHost(width: 350)
        var hapticCount = 0
        card.onThresholdHaptic = { hapticCount += 1 }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: -112 * 0.999, y: 0), .zero)
        ])

        XCTAssertEqual(hapticCount, 0)
        XCTAssertFalse(card.didTriggerThresholdHaptic)
    }

    @MainActor
    func test_SwipeCard_PullBackToExact085_DoesNotResetHaptic() {
        let (_, card) = makeCardHost(width: 350)
        var hapticCount = 0
        card.onThresholdHaptic = { hapticCount += 1 }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 112, y: 0), .zero),
            (.changed, CGPoint(x: 112 * 0.85, y: 0), .zero)
        ])
        XCTAssertTrue(card.didTriggerThresholdHaptic)

        drivePan(card, steps: [
            (.changed, CGPoint(x: 112, y: 0), .zero)
        ])
        XCTAssertEqual(hapticCount, 1)
    }

    @MainActor
    func test_SwipeCard_PullBackTo0849_ResetsAndRefires() {
        let (_, card) = makeCardHost(width: 350)
        var hapticCount = 0
        card.onThresholdHaptic = { hapticCount += 1 }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 112, y: 0), .zero),
            (.changed, CGPoint(x: 112 * 0.849, y: 0), .zero)
        ])
        XCTAssertFalse(card.didTriggerThresholdHaptic)

        drivePan(card, steps: [
            (.changed, CGPoint(x: 112, y: 0), .zero)
        ])
        XCTAssertEqual(hapticCount, 2)
    }

    @MainActor
    func test_SwipeCard_ZeroBoundsWidth_NeverFiresHaptic() {
        let (_, card) = makeCardHost(width: 0)
        var hapticCount = 0
        card.onThresholdHaptic = { hapticCount += 1 }

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 50, y: 0), .zero)
        ])

        XCTAssertEqual(hapticCount, 0)
        XCTAssertFalse(card.didTriggerThresholdHaptic)
    }

    @MainActor
    func test_SwipeCard_CancelAfterThresholdOrNearThreshold_ResetsHapticFlag() {
        let (_, card) = makeCardHost(width: 350)
        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 112, y: 0), .zero),
            (.ended, CGPoint(x: 2, y: 0), .zero)
        ])
        XCTAssertFalse(card.didTriggerThresholdHaptic)

        drivePan(card, steps: [
            (.began, .zero, .zero),
            (.changed, CGPoint(x: 112, y: 0), .zero),
            (.cancelled, CGPoint(x: 100, y: 0), .zero)
        ])
        XCTAssertFalse(card.didTriggerThresholdHaptic)
    }
}
