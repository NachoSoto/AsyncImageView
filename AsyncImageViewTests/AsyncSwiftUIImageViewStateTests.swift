import SwiftUI
import UIKit

import ReactiveSwift
import Testing

@testable import AsyncImageView

@Suite @MainActor
struct AsyncSwiftUIImageViewStateTests {
    @Test
    func supportsEverySchedulerInitializerCombination() {
        let renderer = StateTestRenderer()

        _ = StateTestImageView(renderer: renderer)
        _ = StateTestImageView(renderer: renderer, uiScheduler: ImmediateScheduler())
        _ = StateTestImageView(renderer: renderer, imageCreationScheduler: ImmediateScheduler())
        _ = StateTestImageView(
            renderer: renderer,
            uiScheduler: ImmediateScheduler(),
            imageCreationScheduler: ImmediateScheduler()
        )
    }

    @Test
    func createsRetainedSchedulersOnceAcrossParentUpdates() {
        let schedulerFactory = SchedulerFactory()
        let renderer = StateTestRenderer()
        let initialView = StateTestContainer(
            generation: 0,
            renderer: renderer,
            schedulerFactory: schedulerFactory
        )
        let viewController = UIHostingController(rootView: initialView)
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.view.frame = window.bounds
        viewController.view.layoutIfNeeded()

        for generation in 1...100 {
            viewController.rootView = StateTestContainer(
                    generation: generation,
                    renderer: renderer,
                    schedulerFactory: schedulerFactory
                )
            viewController.view.layoutIfNeeded()
        }

        #expect(schedulerFactory.uiSchedulerCount.value == 1)
        #expect(schedulerFactory.imageSchedulerCount.value == 1)
    }
}

private struct StateTestContainer: View {
    let generation: Int
    let renderer: StateTestRenderer
    let schedulerFactory: SchedulerFactory

    var body: some View {
        StateTestImageView(
            renderer: self.renderer,
            placeholderRenderer: nil,
            uiSchedulerFactory: self.schedulerFactory.makeUIScheduler,
            imageCreationSchedulerFactory: self.schedulerFactory.makeImageScheduler
        )
        .frame(width: 100, height: 100)
        .accessibilityIdentifier("generation-\(self.generation)")
    }
}

private typealias StateTestImageView = AsyncSwiftUIImageView<
    StateTestRenderData,
    StateTestViewData,
    StateTestRenderer,
    StateTestRenderer
>

private final class SchedulerFactory {
    let uiSchedulerCount = Atomic(0)
    let imageSchedulerCount = Atomic(0)

    func makeUIScheduler() -> ReactiveSwift.Scheduler {
        self.uiSchedulerCount.modify { $0 += 1 }
        return ImmediateScheduler()
    }

    func makeImageScheduler() -> ReactiveSwift.Scheduler {
        self.imageSchedulerCount.modify { $0 += 1 }
        return ImmediateScheduler()
    }
}

private struct StateTestViewData: ImageViewDataType {
    func renderDataWithSize(_ size: CGSize) -> StateTestRenderData {
        StateTestRenderData(size: size)
    }
}

private struct StateTestRenderData: RenderDataType {
    let size: CGSize
}

private final class StateTestRenderer: RendererType {
    func renderImageWithData(_ data: StateTestRenderData) -> SignalProducer<UIImage, Never> {
        SignalProducer(value: UIImage())
    }
}
