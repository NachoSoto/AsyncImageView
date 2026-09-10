import UIKit

import ReactiveSwift
import Testing

import AsyncImageView

@Suite @MainActor
struct AsyncImageTransitionTests {
    @Test(arguments: [true, false])
    func explicitCrossfadeAnimatesRegardlessOfCacheStatus(cacheHit: Bool) {
        let fixture = TransitionFixture()
        fixture.view.setData(.a, transition: .crossfade(duration: 0.6))
        fixture.renderer.emit(.a, cacheHit: cacheHit)

        #expect(fixture.view.animationDurations.last == 0.6)
    }

    @Test(arguments: [true, false])
    func explicitNoneNeverAnimates(cacheHit: Bool) {
        let fixture = TransitionFixture()
        fixture.view.setData(.a, transition: .none)
        fixture.renderer.emit(.a, cacheHit: cacheHit)

        #expect(fixture.view.animationDurations.last == 0)
    }

    @Test(arguments: [true, false])
    func dataAssignmentPreservesCacheDependentAnimation(cacheHit: Bool) {
        let fixture = TransitionFixture()
        fixture.view.data = .a
        fixture.renderer.emit(.a, cacheHit: cacheHit)

        #expect(fixture.view.animationDurations.last == (cacheHit ? 0 : 0.3))
    }

    @Test(arguments: [true, false])
    func keepsCurrentImageWhileReplacementLoads(hasPlaceholder: Bool) {
        let fixture = TransitionFixture(hasPlaceholder: hasPlaceholder)
        let original = fixture.loadOriginal()
        let placeholderRequests = fixture.placeholder.requests

        fixture.view.setData(.b, placeholderPolicy: .keepCurrentImage)

        #expect(fixture.view.image === original)
        #expect(fixture.placeholder.requests == placeholderRequests)
        let replacement = fixture.renderer.emit(.b)
        #expect(fixture.view.image === replacement)
    }

    @Test
    func usesPlaceholderWhenThereIsNoCurrentImage() {
        let fixture = TransitionFixture()
        fixture.view.setData(.a, placeholderPolicy: .keepCurrentImage)
        let placeholder = fixture.placeholder.emit(.a)

        #expect(fixture.view.image === placeholder)
        let replacement = fixture.renderer.emit(.a)
        #expect(fixture.view.image === replacement)
    }

    @Test
    func duplicateDataUpdateDoesNotChangePendingTransition() {
        let fixture = TransitionFixture()
        _ = fixture.loadOriginal()
        fixture.view.setData(.b, transition: .crossfade(duration: 0.6), placeholderPolicy: .keepCurrentImage)
        fixture.view.data = .b
        fixture.renderer.emit(.b, cacheHit: true)

        #expect(fixture.renderer.requests == [.a, .b])
        #expect(fixture.view.animationDurations.last == 0.6)
    }

    @Test
    func staleReplacementCannotOverwriteNewerRequest() {
        let fixture = TransitionFixture()
        _ = fixture.loadOriginal()
        fixture.view.setData(.b, transition: .crossfade(), placeholderPolicy: .keepCurrentImage)
        fixture.view.setData(.c, transition: .none, placeholderPolicy: .keepCurrentImage)
        let latest = fixture.renderer.emit(.c)
        fixture.renderer.emit(.b)

        #expect(fixture.view.image === latest)
        #expect(fixture.view.animationDurations.last == 0)
    }

    @Test
    func nilClearsImageAndCancelsRetainedReplacement() {
        let fixture = TransitionFixture()
        _ = fixture.loadOriginal()
        fixture.view.setData(.b, placeholderPolicy: .keepCurrentImage)
        fixture.view.setData(nil, transition: .crossfade(), placeholderPolicy: .keepCurrentImage)
        fixture.renderer.emit(.b)

        #expect(fixture.view.image == nil)
    }

    @Test
    func emptyReplacementPreservesCurrentImage() {
        let fixture = TransitionFixture()
        let original = fixture.loadOriginal()
        fixture.view.setData(.b, placeholderPolicy: .keepCurrentImage)
        fixture.renderer.complete(.b)

        #expect(fixture.view.image === original)
        fixture.view.setData(.c, placeholderPolicy: .keepCurrentImage)
        let replacement = fixture.renderer.emit(.c)
        #expect(fixture.view.image === replacement)
    }

    @Test
    func deferredRequestPreservesTransition() {
        let fixture = TransitionFixture(size: .zero)
        fixture.view.setData(.a, transition: .crossfade(duration: 0.6))
        #expect(fixture.renderer.requests.isEmpty)
        fixture.view.frame.size = CGSize(width: 10, height: 10)
        fixture.renderer.emit(.a, cacheHit: true)

        #expect(fixture.view.animationDurations.last == 0.6)
    }
}

@MainActor
private final class TransitionFixture {
    let renderer = TransitionRenderer()
    let placeholder = TransitionRenderer(color: .blue)
    let view: TransitionRecordingView
    private let window = UIWindow()

    init(hasPlaceholder: Bool = true, size: CGSize = CGSize(width: 10, height: 10)) {
        self.view = TransitionRecordingView(
            initialFrame: CGRect(origin: .zero, size: size),
            renderer: self.renderer,
            placeholderRenderer: hasPlaceholder ? self.placeholder : nil,
            uiScheduler: ImmediateScheduler(),
            imageCreationScheduler: ImmediateScheduler()
        )
        self.window.addSubview(self.view)
    }

    func loadOriginal() -> UIImage {
        self.view.data = .a
        return self.renderer.emit(.a)
    }
}

private final class TransitionRecordingView: AsyncImageView<TestRenderData, TestData, TransitionRenderer, TransitionRenderer> {
    var animationDurations: [TimeInterval] = []

    override var image: UIImage? {
        didSet {
            if self.image != nil {
                self.animationDurations.append(UIView.inheritedAnimationDuration)
            }
        }
    }
}

private final class TransitionRenderer: RendererType {
    private var observers: [TestData: Signal<ImageResult, Never>.Observer] = [:]
    private(set) var requests: [TestData] = []
    private let color: UIColor

    init(color: UIColor = .red) {
        self.color = color
    }

    func renderImageWithData(_ data: TestRenderData) -> SignalProducer<ImageResult, Never> {
        self.requests.append(data.data)
        let (signal, observer) = Signal<ImageResult, Never>.pipe()
        self.observers[data.data] = observer
        return SignalProducer(signal)
    }

    @discardableResult
    func emit(_ data: TestData, cacheHit: Bool = true) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = data.rawValue
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format).image { context in
            self.color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        self.observers[data]?.send(value: ImageResult(image: image, cacheHit: cacheHit))
        return image
    }

    func complete(_ data: TestData) {
        self.observers[data]?.sendCompleted()
    }
}
