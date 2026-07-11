import Quick
import Nimble
import SwiftUI
import UIKit

import ReactiveSwift

import AsyncImageView

class AsyncSwiftUIImageViewSpec: QuickSpec {
    override class func spec() {
        describe("AsyncSwiftUIImageView") {
            it("requests the full proposed size") {
                let renderer = TestRenderer()
                typealias ViewType = AsyncSwiftUIImageView<
                    TestRenderData,
                    TestData,
                    TestRenderer,
                    TestRenderer
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

                expect(renderer.renderedImages.value).toEventually(
                    contain(TestRenderData(data: .a, size: window.bounds.size))
                )
            }
        }
    }
}
