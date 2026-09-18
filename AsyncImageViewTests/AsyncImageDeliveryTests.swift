import UIKit
import ReactiveSwift
import Testing

import AsyncImageView

@Suite(.serialized) @MainActor
struct AsyncImageDeliveryTests {
    @Test
    func currentBackgroundResultIsDelivered() async {
        let scheduler = TestScheduler()
        let fixture = DeliveryFixture(imageCreationScheduler: scheduler)
        fixture.view.setData(.a, transition: .none)
        self.advance(scheduler)
        let image = fixture.renderer.enqueueResult()

        await self.drainMainQueue()

        #expect(fixture.view.image === image)
    }

    @Test
    func supersededCreationIsCancelledAndDuplicateDataIsDeduplicated() {
        let scheduler = TestScheduler()
        let fixture = DeliveryFixture(imageCreationScheduler: scheduler)
        fixture.view.setData(.a)
        fixture.view.setData(.c)
        fixture.view.setData(.c, transition: .crossfade())
        scheduler.advance()

        #expect(fixture.renderer.requests.value == [.c])
    }

    @Test(arguments: [TestData?.none, .c])
    func replacementCancelsDeliveryBeforeCreationSchedulerRuns(replacementData: TestData?) async {
        let scheduler = TestScheduler()
        let fixture = DeliveryFixture(hasPlaceholder: true, imageCreationScheduler: scheduler)
        fixture.view.setData(.b, transition: .none)
        self.advance(scheduler)
        let original = fixture.view.image
        #expect(original != nil)
        fixture.view.setData(.a, transition: .none, placeholderPolicy: .keepCurrentImage)
        self.advance(scheduler)
        let staleImage = fixture.renderer.enqueueResult()

        fixture.view.setData(replacementData, transition: .none, placeholderPolicy: .keepCurrentImage)
        // Do not advance creation: cancellation must happen at the request boundary.
        await self.drainMainQueue()

        #expect(!fixture.view.displayedImages.contains { $0 === staleImage })
        #expect(fixture.view.image === (replacementData == nil ? nil : original))
        self.advance(scheduler)
        #expect(fixture.view.image === (replacementData == nil ? nil : original))
    }

    @Test(arguments: [TestData?.none, .b, .c], [true, false])
    func replacementCancelsImageAlreadyQueuedForDisplay(replacementData: TestData?, hasPlaceholder: Bool) async {
        let fixture = DeliveryFixture(hasPlaceholder: hasPlaceholder)
        fixture.view.setData(.a, transition: .none)

        // Finish rendering off-main while main is occupied, just as during snapshotting.
        // The image has left the renderer but has not reached the UIImageView yet.
        let staleImage = fixture.renderer.enqueueResult()
        fixture.view.setData(replacementData, transition: .none)
        let replacement = fixture.view.image

        await self.drainMainQueue()

        #expect(fixture.view.image === replacement)
        #expect(!fixture.view.displayedImages.contains { $0 === staleImage })
        if replacementData == nil {
            #expect(fixture.view.image == nil)
        }
    }

    private func advance(_ scheduler: TestScheduler) {
        scheduler.advance()
    }

    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}

@MainActor
private final class DeliveryFixture {
    let renderer = DeliveryRenderer()
    let view: DeliveryRecordingView
    private let window = UIWindow()

    init(hasPlaceholder: Bool = false, imageCreationScheduler: ReactiveSwift.Scheduler = ImmediateScheduler()) {
        self.view = DeliveryRecordingView(
            initialFrame: CGRect(x: 0, y: 0, width: 10, height: 10),
            renderer: self.renderer,
            placeholderRenderer: hasPlaceholder ? DeliveryRenderer() : nil,
            uiScheduler: ImmediateScheduler(),
            imageCreationScheduler: imageCreationScheduler
        )
        self.window.addSubview(self.view)
    }
}

private final class DeliveryRecordingView: AsyncImageView<TestRenderData, TestData, DeliveryRenderer, DeliveryRenderer> {
    var displayedImages: [UIImage] = []

    override var image: UIImage? {
        didSet {
            if let image {
                self.displayedImages.append(image)
            }
        }
    }
}

private final class DeliveryRenderer: RendererType, @unchecked Sendable {
    let requests = Atomic<[TestData]>([])
    private let observer = Atomic<Signal<UIImage, Never>.Observer?>(nil)

    func renderImageWithData(_ data: TestRenderData) -> SignalProducer<UIImage, Never> {
        self.requests.modify { $0.append(data.data) }
        if data.data == .b {
            return SignalProducer(value: Self.image(color: .blue))
        }
        return SignalProducer { observer, _ in
            self.observer.swap(observer)
        }
    }

    func enqueueResult() -> UIImage {
        let image = Self.image(color: .red)
        let finished = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            self.observer.value?.send(value: image)
            finished.signal()
        }
        finished.wait()
        return image
    }

    private static func image(color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}
