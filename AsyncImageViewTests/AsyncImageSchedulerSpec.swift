import Quick
import Nimble
import UIKit

import ReactiveSwift

import AsyncImageView

class AsyncImageSchedulerSpec: QuickSpec {
	override class func spec() {
		describe("AsyncImageView scheduling") {
			it("schedules image creation once per request") {
				let imageCreationScheduler = CountingScheduler()
				let renderer = SchedulerCheckingRenderer(scheduler: imageCreationScheduler)
				let view = AsyncImageView<
					TestRenderData,
					TestData,
					SchedulerCheckingRenderer,
					SchedulerCheckingRenderer
				>(
					initialFrame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)),
					renderer: renderer,
					placeholderRenderer: nil,
					uiScheduler: ImmediateScheduler(),
					imageCreationScheduler: imageCreationScheduler
				)
				let window = UIWindow()
				window.addSubview(view)
				imageCreationScheduler.reset()

				view.data = .a

				expect(imageCreationScheduler.scheduleCount.value) == 1
				expect(renderer.startedOnScheduler.value) == true
			}
		}
	}
}

private final class CountingScheduler: Scheduler {
	let scheduleCount = Atomic(0)
	let isExecuting = Atomic(false)

	func schedule(_ action: @escaping () -> Void) -> Disposable? {
		self.scheduleCount.modify { $0 += 1 }
		self.isExecuting.modify { $0 = true }
		action()
		self.isExecuting.modify { $0 = false }

		return nil
	}

	func reset() {
		self.scheduleCount.modify { $0 = 0 }
	}
}

private final class SchedulerCheckingRenderer: RendererType {
	let startedOnScheduler = Atomic(false)
	private let scheduler: CountingScheduler

	init(scheduler: CountingScheduler) {
		self.scheduler = scheduler
	}

	func renderImageWithData(_ data: TestRenderData) -> SignalProducer<UIImage, Never> {
		self.startedOnScheduler.modify { $0 = self.scheduler.isExecuting.value }

		return SignalProducer(value: UIImage())
	}
}
