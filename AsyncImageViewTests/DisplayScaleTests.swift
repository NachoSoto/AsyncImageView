import SwiftUI
import UIKit
import ReactiveSwift
import Testing

import AsyncImageView

@MainActor
struct DisplayScaleTests {
    @Test(arguments: [Framework.uiKit, .swiftUI])
    func requestsAgainWhenOnlyDisplayScaleChanges(framework: Framework) {
        let renderer = ScaleRenderer()
        let size = CGSize(width: 20, height: 20)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let updateScale: (CGFloat) -> Void
        switch framework {
        case .uiKit:
            let view = AsyncImageView<ScaleData, ScaleViewData, ScaleRenderer, ScaleRenderer>(
                initialFrame: CGRect(origin: .zero, size: size),
                renderer: renderer, uiScheduler: ImmediateScheduler(), imageCreationScheduler: ImmediateScheduler()
            )
            window.addSubview(view)
            view.data = ScaleViewData()
            updateScale = { window.traitOverrides.displayScale = $0 }
        case .swiftUI:
            let view = AsyncSwiftUIImageView<ScaleData, ScaleViewData, ScaleRenderer, ScaleRenderer>(
                renderer: renderer, uiScheduler: ImmediateScheduler(), imageCreationScheduler: ImmediateScheduler()
            ).data(ScaleViewData()).frame(width: size.width, height: size.height)
            let controller = UIHostingController(rootView: view.environment(\.displayScale, 2))
            window.rootViewController = controller
            updateScale = { controller.rootView = view.environment(\.displayScale, $0) }
        }
        window.makeKeyAndVisible()

        for scale: CGFloat in [2, 3] {
            updateScale(scale)
            window.layoutIfNeeded()
            #expect(eventually { renderer.requests.value.last?.displayScale == scale })
            #expect(renderer.requests.value.last?.size == size)
        }
    }

    enum Framework {
        case uiKit, swiftUI
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
