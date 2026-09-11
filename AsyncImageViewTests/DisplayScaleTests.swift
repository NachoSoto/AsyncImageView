import SwiftUI
import UIKit
import ReactiveSwift
import Testing

import AsyncImageView

@MainActor
struct DisplayScaleTests {
    @Test
    func uikitRequestsAgainWhenOnlyDisplayScaleChanges() {
        let renderer = ScaleRenderer()
        let view = AsyncImageView<ScaleData, ScaleViewData, ScaleRenderer, ScaleRenderer>(
            initialFrame: CGRect(x: 0, y: 0, width: 20, height: 20),
            renderer: renderer, uiScheduler: ImmediateScheduler(), imageCreationScheduler: ImmediateScheduler()
        )
        let window = UIWindow()
        window.traitOverrides.displayScale = 2
        window.addSubview(view)
        view.data = ScaleViewData()
        #expect(renderer.requests.value.last?.displayScale == 2)

        window.traitOverrides.displayScale = 3
        view.layoutIfNeeded()
        #expect(eventually { renderer.requests.value.last?.displayScale == 3 })
        #expect(view.image?.size == CGSize(width: 20, height: 20))
        #expect(view.image?.cgImage?.width == 60)
    }

    @Test
    func swiftuiRequestsAgainWhenOnlyEnvironmentScaleChanges() {
        let renderer = ScaleRenderer()
        let view = AsyncSwiftUIImageView<ScaleData, ScaleViewData, ScaleRenderer, ScaleRenderer>(
            renderer: renderer, uiScheduler: ImmediateScheduler(), imageCreationScheduler: ImmediateScheduler()
        ).data(ScaleViewData()).frame(width: 20, height: 20)
        let controller = UIHostingController(rootView: view.environment(\.displayScale, 2))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        #expect(eventually { renderer.requests.value.last?.displayScale == 2 })

        controller.rootView = view.environment(\.displayScale, 3)
        controller.view.layoutIfNeeded()
        #expect(eventually { renderer.requests.value.last?.displayScale == 3 })
        #expect(renderer.requests.value.last?.size == CGSize(width: 20, height: 20))
    }

    @Test(arguments: [CGFloat(2), 3])
    func inflationUsesRequestScale(displayScale: CGFloat) async throws {
        let data = ScaleData(size: CGSize(width: 20, height: 20), displayScale: displayScale)
        let result = await withCheckedContinuation { continuation in
            ScaleRenderer().inflated(opaque: true).renderImageWithData(data).take(first: 1).startWithValues {
                continuation.resume(returning: $0.image)
            }
        }
        #expect(result.size == data.size)
        #expect(result.scale == displayScale)
        #expect(result.cgImage?.width == Int(20 * displayScale))
    }
}

private struct ScaleViewData: ImageViewDataType {
    func renderDataWithSize(_ size: CGSize) -> ScaleData {
        ScaleData(size: size, displayScale: 1)
    }

    func renderDataWithSize(_ size: CGSize, displayScale: CGFloat) -> ScaleData {
        ScaleData(size: size, displayScale: displayScale)
    }
}

private struct ScaleData: RenderDataType {
    let size: CGSize
    let displayScale: CGFloat
}

private final class ScaleRenderer: RendererType {
    let requests = Atomic<[ScaleData]>([])

    func renderImageWithData(_ data: ScaleData) -> SignalProducer<UIImage, Never> {
        self.requests.modify { $0.append(data) }
        return ContextRenderer<ScaleData>(opaque: true) { context, data in
            context.setFillColor(UIColor.red.cgColor)
            context.fill(CGRect(origin: .zero, size: data.size))
        }.asyncRenderer(ImmediateScheduler()).renderImageWithData(data)
    }
}
