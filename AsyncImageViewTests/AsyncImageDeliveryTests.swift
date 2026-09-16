import UIKit
import ReactiveSwift
import Testing

import AsyncImageView

@Suite(.serialized) @MainActor
struct AsyncImageDeliveryTests {
    @Test
    func currentBackgroundResultIsDelivered() async {
        let renderer = DeliveryRenderer()
        let scheduler = TestScheduler()
        let view = DeliveryRecordingView(
            initialFrame: CGRect(x: 0, y: 0, width: 10, height: 10),
            renderer: renderer,
            placeholderRenderer: nil,
            uiScheduler: ImmediateScheduler(),
            imageCreationScheduler: scheduler
        )
        let window = UIWindow()
        window.addSubview(view)
        view.setData(.a, transition: .none)
        self.advance(scheduler)
        let image = renderer.enqueueResult()
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        #expect(view.image === image)
        _ = window
    }

    @Test
    func supersededCreationIsCancelledAndDuplicateDataIsDeduplicated() {
        let scheduler = TestScheduler()
        let renderer = DeliveryRenderer()
        let view = DeliveryRecordingView(
            initialFrame: CGRect(x: 0, y: 0, width: 10, height: 10),
            renderer: renderer,
            placeholderRenderer: nil,
            uiScheduler: ImmediateScheduler(),
            imageCreationScheduler: scheduler
        )
        let window = UIWindow()
        window.addSubview(view)
        view.setData(.a)
        view.setData(.c)
        view.setData(.c, transition: .crossfade())
        scheduler.advance()

        #expect(renderer.requests.value == [.c])
        _ = window
    }

    @Test(arguments: [TestData?.none, .c])
    func replacementCancelsDeliveryBeforeCreationSchedulerRuns(replacementData: TestData?) async {
        let scheduler = TestScheduler()
        let renderer = DeliveryRenderer()
        let view = DeliveryRecordingView(
            initialFrame: CGRect(x: 0, y: 0, width: 10, height: 10),
            renderer: renderer,
            placeholderRenderer: DeliveryRenderer(),
            uiScheduler: ImmediateScheduler(),
            imageCreationScheduler: scheduler
        )
        let window = UIWindow()
        window.addSubview(view)
        view.setData(.b, transition: .none)
        self.advance(scheduler)
        let original = view.image
        #expect(original != nil)
        view.setData(.a, transition: .none, placeholderPolicy: .keepCurrentImage)
        self.advance(scheduler)
        let staleImage = renderer.enqueueResult()

        view.setData(replacementData, transition: .none, placeholderPolicy: .keepCurrentImage)
        // Do not advance creation: cancellation must happen at the request boundary.
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        #expect(!view.displayedImages.contains { $0 === staleImage })
        #expect(view.image === (replacementData == nil ? nil : original))
        self.advance(scheduler)
        #expect(view.image === (replacementData == nil ? nil : original))
        _ = window
    }

    private func advance(_ scheduler: TestScheduler) {
        scheduler.advance()
    }

    @Test(arguments: [TestData?.none, .b, .c], [true, false])
    func replacementCancelsImageAlreadyQueuedForDisplay(replacementData: TestData?, hasPlaceholder: Bool) async {
        let renderer = DeliveryRenderer()
        let view = DeliveryRecordingView(
            initialFrame: CGRect(x: 0, y: 0, width: 10, height: 10),
            renderer: renderer,
            placeholderRenderer: hasPlaceholder ? DeliveryRenderer() : nil,
            uiScheduler: ImmediateScheduler(),
            imageCreationScheduler: ImmediateScheduler()
        )
        let window = UIWindow()
        window.addSubview(view)
        view.setData(.a, transition: .none)

        // Finish rendering off-main while main is occupied, just as during snapshotting.
        // The image has left the renderer but has not reached the UIImageView yet.
        let staleImage = renderer.enqueueResult()
        view.setData(replacementData, transition: .none)
        let replacement = view.image

        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }

        #expect(view.image === replacement)
        #expect(!view.displayedImages.contains { $0 === staleImage })
        if replacementData == nil {
            #expect(view.image == nil)
        }
        _ = window
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
