import SwiftUI
import UIKit

import ReactiveSwift
import Testing

import AsyncImageView

@Suite @MainActor
struct AsyncSwiftUIImageViewTests {
    @Test
    func requestsFullProposedSizeOnlyOnce() {
        let renderer = SquareImageRenderer()
        typealias ViewType = AsyncSwiftUIImageView<
            TestRenderData,
            TestData,
            SquareImageRenderer,
            SquareImageRenderer
        >
        let view = ViewType(
            renderer: renderer,
            placeholderRenderer: nil,
            uiScheduler: ImmediateScheduler(),
            imageCreationScheduler: ImmediateScheduler()
        )
        .data(.a)
        .frame(width: 300, height: 100)
        let viewController = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 300, height: 100)))
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.view.frame = window.bounds
        viewController.view.layoutIfNeeded()

        let expectedRequest = TestRenderData(data: .a, size: window.bounds.size)
        #expect(eventually { renderer.renderedImages.value == [expectedRequest] })

        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        viewController.view.layoutIfNeeded()

        #expect(renderer.renderedImages.value == [expectedRequest])
    }
}

private final class SquareImageRenderer: RendererType {
    let renderedImages = Atomic<[TestRenderData]>([])

    func renderImageWithData(_ data: TestRenderData) -> SignalProducer<UIImage, Never> {
        TestRenderer.rendererForSize(CGSize(width: 100, height: 100), scale: 1)
            .asyncRenderer(ImmediateScheduler())
            .renderImageWithData(data)
            .on(started: {
                self.renderedImages.modify { $0.append(data) }
            })
    }
}
