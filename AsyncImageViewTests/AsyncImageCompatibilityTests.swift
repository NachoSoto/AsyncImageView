import UIKit

import ReactiveSwift
import Testing

import AsyncImageView

/// Exercises the existing `.data` API with a controlled UI scheduler.
/// These tests also run unchanged against the pre-transition implementation.
@Suite @MainActor
struct AsyncImageCompatibilityTests {
    private let fixture = CompatibilityFixture()

    @Test
    func preparesPlaceholderBeforeMainRenderer() {
        self.fixture.view.data = .a

        #expect(self.fixture.requests.value == ["placeholder", "source"])
    }

    @Test
    func synchronousSourceBypassesScheduledPlaceholder() {
        self.fixture.source.isSynchronous = true
        self.fixture.view.data = .a

        #expect(self.fixture.view.image === self.fixture.source.image)
        self.fixture.scheduler.run()
        #expect(self.fixture.view.image === self.fixture.source.image)
        #expect(self.fixture.view.displayedImages.count == 1)
    }

    @Test
    func sourceReplacementCancelsPendingPlaceholderDelivery() {
        self.fixture.view.data = .a
        self.fixture.source.sendImage()

        #expect(self.fixture.view.image === self.fixture.source.image)
        self.fixture.scheduler.run()
        #expect(self.fixture.view.image === self.fixture.source.image)
        #expect(self.fixture.view.displayedImages.count == 1)
    }

    @Test
    func withoutPlaceholderSourceUsesUISchedulerAndClearsOldImage() {
        let fixture = CompatibilityFixture(hasPlaceholder: false)
        fixture.view.image = fixture.placeholder.image
        fixture.source.isSynchronous = true
        fixture.view.data = .a

        #expect(fixture.view.image == nil)
        fixture.scheduler.run()
        #expect(fixture.view.image === fixture.source.image)
    }
}

@MainActor
private final class CompatibilityFixture {
    let scheduler = TestScheduler()
    let requests = Atomic<[String]>([])
    let source: CompatibilityRenderer
    let placeholder: CompatibilityRenderer
    let view: CompatibilityImageView
    private let window = UIWindow()

    init(hasPlaceholder: Bool = true) {
        self.source = CompatibilityRenderer(name: "source", requests: self.requests, scale: 1)
        self.placeholder = CompatibilityRenderer(name: "placeholder", requests: self.requests, scale: 2)
        self.placeholder.isSynchronous = true
        self.view = CompatibilityImageView(
            initialFrame: CGRect(x: 0, y: 0, width: 10, height: 10),
            renderer: self.source,
            placeholderRenderer: hasPlaceholder ? self.placeholder : nil,
            uiScheduler: self.scheduler,
            imageCreationScheduler: ImmediateScheduler()
        )
        self.window.addSubview(self.view)
    }
}

private final class CompatibilityImageView: AsyncImageView<TestRenderData, TestData, CompatibilityRenderer, CompatibilityRenderer> {
    var displayedImages: [UIImage] = []

    override var image: UIImage? {
        didSet {
            if let image = self.image {
                self.displayedImages.append(image)
            }
        }
    }
}

private final class CompatibilityRenderer: RendererType {
    let image: UIImage
    var isSynchronous = false
    private let name: String
    private let requests: Atomic<[String]>
    private var observer: Signal<UIImage, Never>.Observer?

    init(name: String, requests: Atomic<[String]>, scale: CGFloat) {
        self.name = name
        self.requests = requests
        self.image = TestRenderer.rendererForSize(CGSize(width: 1, height: 1), scale: scale)
            .renderImageWithData(TestRenderData(data: .a, size: CGSize(width: 1, height: 1)))
    }

    func renderImageWithData(_ data: TestRenderData) -> SignalProducer<UIImage, Never> {
        self.requests.modify { $0.append(self.name) }
        if self.isSynchronous {
            return SignalProducer(value: self.image)
        } else {
            let (signal, observer) = Signal<UIImage, Never>.pipe()
            self.observer = observer
            return SignalProducer(signal)
        }
    }

    func sendImage() {
        self.observer?.send(value: self.image)
    }
}
