import UIKit
import ReactiveSwift
import Testing

import AsyncImageView

@Suite @MainActor
struct AsyncImageDeliveryTests {
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
    private let observer = Atomic<Signal<UIImage, Never>.Observer?>(nil)

    func renderImageWithData(_ data: TestRenderData) -> SignalProducer<UIImage, Never> {
        if data.data == .b {
            return SignalProducer(value: UIImage())
        }
        return SignalProducer { observer, _ in
            self.observer.swap(observer)
        }
    }

    func enqueueResult() -> UIImage {
        let image = UIImage()
        let finished = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            self.observer.value?.send(value: image)
            finished.signal()
        }
        finished.wait()
        return image
    }
}
