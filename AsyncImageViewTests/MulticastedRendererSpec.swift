//
//  MulticastedRendererSpec.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import Quick
import Nimble

import Result
import ReactiveCocoa

import AsyncImageView

class MulticastedRendererSpec: QuickSpec {
	override func spec() {
		describe("MulticastedRenderer") {
			let data: TestData = .A
			let size = CGSize(width: 1, height: 1)

			context("General tests") {
				typealias InnerRendererType = AnyRenderer<TestRenderData, UIImage, NoError>
				typealias RenderType = MulticastedRenderer<TestRenderData, InnerRendererType>

				var innerRenderer: InnerRendererType!
				var renderer: RenderType!

				func getProducerForData(data: TestData, _ size: CGSize) -> SignalProducer<ImageResult, NoError> {
					return renderer.renderImageWithData(data.renderDataWithSize(size))
				}

				func getImageForData(data: TestData, _ size: CGSize) -> ImageResult? {
					return getProducerForData(data, size)
						.single()?
						.value
				}

				beforeEach {
					innerRenderer = AnyRenderer(TestRenderer())
					renderer = RenderType(renderer: innerRenderer)
				}

				it("produces an image") {
					let result = getImageForData(data, size)

					verifyImage(result?.image, withSize: size, data: data)
				}

				it("multicasts rendering") {
					// Get both producers at the same time.
					let result1 = getProducerForData(data, size)
					let result2 = getProducerForData(data, size)

					// Starting the producers should yield the same image.
					let image1 = result1.single()?.value?.image
					let image2 = result2.single()?.value?.image

					expect(image1!) === image2!
				}
			}

			context("Cache hit") {
				typealias InnerRendererType = AnyRenderer<TestRenderData, ImageResult, NoError>
				typealias RenderType = MulticastedRenderer<TestRenderData, InnerRendererType>

				var scheduler: TestScheduler!
				let delay: NSTimeInterval = 1

				var innerRenderer: InnerRendererType!
				var renderer: RenderType!

				var cacheHitRenderer: CacheHitRenderer!


				func getProducerForData(data: TestData, _ size: CGSize) -> SignalProducer<ImageResult, NoError> {
					return renderer.renderImageWithData(data.renderDataWithSize(size))
				}

				func getImageForData(data: TestData, _ size: CGSize) -> ImageResult? {
					return getProducerForData(data, size)
						.single()?
						.value
				}

				beforeEach {
					scheduler = TestScheduler()

					cacheHitRenderer = CacheHitRenderer()
					innerRenderer = AnyRenderer(cacheHitRenderer)

					let delayedTestRenderer: InnerRendererType = AnyRenderer(DelayedRenderer(
						renderer: innerRenderer,
						delay: delay,
						scheduler: scheduler
						))

					renderer = RenderType(renderer: delayedTestRenderer)
				}

				func getCacheHitValue() -> Bool {
					let producer = getProducerForData(data, size)
					var result: ImageResult?

					producer.startWithNext { result = $0 }

					scheduler.advanceByInterval(delay)

					expect(result).toEventuallyNot(beNil())

					return result!.cacheHit
				}

				it("does not cache hit the first time") {
					cacheHitRenderer.shouldCacheHit = false

					expect(getCacheHitValue()) == false
				}

				it("does not cache hit the first time even if inner renderer was a hit") {
					cacheHitRenderer.shouldCacheHit = true

					// We asume that the underlying renderer took longer than a simple Property lookup
					expect(getCacheHitValue()) == false
				}

				it("is a cache hit the second time the producer is fetched") {
					let producer = getProducerForData(data, size)
					scheduler.advanceByInterval(delay)

					var result: ImageResult?
					producer.startWithNext { result = $0 }

					expect(result).toEventuallyNot(beNil())
					expect(result?.cacheHit) == true
				}
			}
		}

		fdescribe("replayLazily") {
			var producer: SignalProducer<Int, TestError>!
			var observer: SignalProducer<Int, TestError>.ProducedSignal.Observer!

			var replayedProducer: SignalProducer<Int, TestError>!

			beforeEach {
				let (producerTemp, observerTemp) = SignalProducer<Int, TestError>.buffer(0)
				producer = producerTemp
				observer = observerTemp

				replayedProducer = producer.replayLazily(2)
			}

			context("subscribing to underlying producer") {
				it("emits new values") {
					var last: Int?

					replayedProducer.startWithNext { last = $0 }
					expect(last).to(beNil())

					observer.sendNext(1)
					expect(last) == 1

					observer.sendNext(2)
					expect(last) == 2
				}

				it("emits errors") {
					var error: TestError?

					replayedProducer.startWithFailed { error = $0 }
					expect(error).to(beNil())

					observer.sendFailed(.Default)
					expect(error) == TestError.Default
				}
			}

			context("buffers past values") {
				it("emits last value upon subscription") {
					let disposable = replayedProducer
						.start()

					observer.sendNext(1)
					disposable.dispose()

					var last: Int?

					replayedProducer
						.startWithNext { last = $0 }
					expect(last) == 1
				}

				it("emits last n values upon subscription") {
					var disposable = replayedProducer
						.start()

					observer.sendNext(1)
					observer.sendNext(2)
					observer.sendNext(3)
					observer.sendNext(4)
					disposable.dispose()

					var values: [Int] = []

					disposable = replayedProducer
						.startWithNext { values.append($0) }
					expect(values) == [ 3, 4 ]

					observer.sendNext(5)
					expect(values) == [ 3, 4, 5 ]

					disposable.dispose()
					values = []

					replayedProducer
						.startWithNext { values.append($0) }
					expect(values) == [ 4, 5 ]
				}
			}

			context("starting underying producer") {
				it("starts lazily") {
					var started = false

					let producer = SignalProducer<Int, NoError>(value: 0)
						.on(started: { started = true })
					expect(started) == false

					let replayedProducer = producer
						.replayLazily(1)
					expect(started) == false

					replayedProducer.start()
					expect(started) == true
				}

				it("shares a single subscription") {
					var startedTimes = 0

					let producer = SignalProducer<Int, NoError>.never
						.on(started: { startedTimes++ })
					expect(startedTimes) == 0

					let replayedProducer = producer
						.replayLazily(1)
					expect(startedTimes) == 0

					replayedProducer.start()
					expect(startedTimes) == 1

					replayedProducer.start()
					expect(startedTimes) == 1
				}

				it("does not start multiple times when subscribing multiple times") {
					var startedTimes = 0

					let producer = SignalProducer<Int, NoError>(value: 0)
						.on(started: { startedTimes++ })

					let replayedProducer = producer
						.replayLazily(1)

					expect(startedTimes) == 0
					replayedProducer.start().dispose()
					expect(startedTimes) == 1
					replayedProducer.start().dispose()
					expect(startedTimes) == 1
				}

				it("does not start again if it finished") {
					var startedTimes = 0

					let producer = SignalProducer<Int, NoError>.empty
						.on(started: { startedTimes++ })
					expect(startedTimes) == 0

					let replayedProducer = producer
						.replayLazily(1)
					expect(startedTimes) == 0

					replayedProducer.start()
					expect(startedTimes) == 1

					replayedProducer.start()
					expect(startedTimes) == 1
				}
			}

			context("lifetime") {
				it("does not dispose underlying subscription if the replayed producer is still in memory") {
					var disposed = false

					let producer = SignalProducer<Int, NoError>.never
						.on(disposed: { disposed = true })

					let replayedProducer = producer
						.replayLazily(1)

					expect(disposed) == false
					let disposable = replayedProducer.start()
					expect(disposed) == false

					disposable.dispose()
					expect(disposed) == false
				}

				it("disposes underlying producer when the producer is deallocated") {
					var disposed = false

					let producer = SignalProducer<Int, NoError>.never
						.on(disposed: { disposed = true })

					var replayedProducer = ImplicitlyUnwrappedOptional(producer.replayLazily(1))

					expect(disposed) == false
					let disposable = replayedProducer.start()
					expect(disposed) == false

					disposable.dispose()
					expect(disposed) == false

					replayedProducer = nil
					expect(disposed) == true
				}

				it("does not leak buffered values") {
					final class Value {
						private let deinitBlock: () -> ()

						init(deinitBlock: () -> ()) {
							self.deinitBlock = deinitBlock
						}

						deinit {
							self.deinitBlock()
						}
					}

					var deinitValues = 0

					var producer: SignalProducer<Value, NoError>! = SignalProducer(value: Value { deinitValues++ })
					expect(deinitValues) == 0

					var replayedProducer: SignalProducer<Value, NoError>! = producer
						.replayLazily(1)

					let disposable = replayedProducer
						.start()

					disposable.dispose()
					expect(deinitValues) == 0

					producer = nil
					expect(deinitValues) == 0

					replayedProducer = nil
					expect(deinitValues) == 1
				}
			}
		}
	}
}

private enum TestError: ErrorType {
	case Default
}

/// `RendererType` decorator that returns `RenderResult` values with
/// `cacheHit` set to whatever the value of `shouldCacheHit` is at a given time.
private final class CacheHitRenderer: RendererType {
	var shouldCacheHit: Bool = false

	private let testRenderer = TestRenderer()

	func renderImageWithData(data: TestRenderData) ->  SignalProducer<ImageResult, NoError> {
		return testRenderer.renderImageWithData(data)
			.map {
				return RenderResult(
					image: $0.image,
					cacheHit: self.shouldCacheHit
				)
		}
	}
}

/// `RendererType` decorator which introduces a delay on the resulting image.
private final class DelayedRenderer<T: RendererType>: RendererType {
	private let renderer: T
	private let delay: NSTimeInterval
	private let scheduler: DateSchedulerType

	init(renderer: T, delay: NSTimeInterval, scheduler: DateSchedulerType) {
		self.renderer = renderer
		self.delay = delay
		self.scheduler = scheduler
	}

	func renderImageWithData(data: T.Data) -> SignalProducer<T.RenderResult, T.Error> {
		return renderer
			.renderImageWithData(data)
			.delay(self.delay, onScheduler: self.scheduler)
	}
}
