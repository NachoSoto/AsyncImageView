import UIKit

import ReactiveSwift
import Testing

import AsyncImageView

@Suite @MainActor
struct AsyncImageViewRequestTests {
	private let fixture = RequestFixture()

	@Test
	func frameOriginChangesDoNotCreateRenderData() {
		for offset in 1...10 {
			self.fixture.view.frame.origin.x = CGFloat(offset)
		}

		#expect(self.fixture.requestCount == 1)
	}

	@Test
	func boundsOriginChangesDoNotCreateRenderData() {
		for offset in 1...10 {
			self.fixture.view.bounds.origin.x = CGFloat(offset)
		}

		#expect(self.fixture.requestCount == 1)
	}

	@Test
	func sizeChangesCreateRenderData() {
		self.fixture.view.frame.size = CGSize(width: 20, height: 20)
		self.fixture.view.bounds.size = CGSize(width: 30, height: 30)

		#expect(self.fixture.requestCount == 3)
	}
}

@MainActor
private final class RequestFixture {
	typealias ViewType = AsyncImageView<
		RequestTestRenderData,
		RequestTestViewData,
		RequestTestRenderer,
		RequestTestRenderer
	>

	let counter = Atomic(0)
	let view: ViewType
	private let window = UIWindow()

	var requestCount: Int {
		self.counter.value
	}

	init() {
		self.view = ViewType(
			initialFrame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)),
			renderer: RequestTestRenderer(),
			placeholderRenderer: nil,
			uiScheduler: ImmediateScheduler(),
			imageCreationScheduler: ImmediateScheduler()
		)
		self.window.addSubview(self.view)
		self.view.data = RequestTestViewData(counter: self.counter)
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
		SignalProducer(value: UIImage())
	}
}
