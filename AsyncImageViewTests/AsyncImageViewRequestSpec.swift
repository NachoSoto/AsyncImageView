import Quick
import Nimble
import UIKit

import ReactiveSwift

import AsyncImageView

class AsyncImageViewRequestSpec: QuickSpec {
	override class func spec() {
		describe("AsyncImageView requests") {
			var counter: Atomic<Int>!
			var view: AsyncImageView<
				RequestTestRenderData,
				RequestTestViewData,
				RequestTestRenderer,
				RequestTestRenderer
			>!
			var window: UIWindow!

			beforeEach {
				counter = Atomic(0)
				view = AsyncImageView<
					RequestTestRenderData,
					RequestTestViewData,
					RequestTestRenderer,
					RequestTestRenderer
				>(
					initialFrame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)),
					renderer: RequestTestRenderer(),
					placeholderRenderer: nil,
					uiScheduler: ImmediateScheduler(),
					imageCreationScheduler: ImmediateScheduler()
				)
				window = UIWindow()
				window.addSubview(view)
				view.data = RequestTestViewData(counter: counter)
			}

			it("does not create render data for frame origin changes") {
				for offset in 1...10 {
					view.frame.origin.x = CGFloat(offset)
				}

				expect(counter.value) == 1
			}

			it("does not create render data for bounds origin changes") {
				for offset in 1...10 {
					view.bounds.origin.x = CGFloat(offset)
				}

				expect(counter.value) == 1
			}

			it("creates render data for size changes") {
				view.frame.size = CGSize(width: 20, height: 20)
				view.bounds.size = CGSize(width: 30, height: 30)

				expect(counter.value) == 3
			}
		}
	}
}

private struct RequestTestViewData: ImageViewDataType {
	let counter: Atomic<Int>

	func renderDataWithSize(_ size: CGSize) -> RequestTestRenderData {
		self.counter.modify { $0 += 1 }

		return RequestTestRenderData(size: size)
	}
}

private struct RequestTestRenderData: RenderDataType {
	let size: CGSize
}

private final class RequestTestRenderer: RendererType {
	func renderImageWithData(_ data: RequestTestRenderData) -> SignalProducer<UIImage, Never> {
		return SignalProducer(value: UIImage())
	}
}
