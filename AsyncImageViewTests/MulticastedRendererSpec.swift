//
//  MulticastedRendererSpec.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import Quick
import Nimble

import ReactiveSwift

import AsyncImageView

class MulticastedRendererSpec: QuickSpec {
	override func spec() {
		describe("MulticastedRenderer") {
			let data: TestData = .a
			let size = CGSize(width: 1, height: 1)

			context("General tests") {
				typealias InnerRendererType = AnyRenderer<TestRenderData, UIImage, Never>
				typealias RenderType = MulticastedRenderer<InnerRendererType, TestRenderData>

				var innerRenderer: InnerRendererType!
				var renderer: RenderType!

				func getProducerForData(_ data: TestData, _ size: CGSize) -> SignalProducer<ImageResult, Never> {
					return renderer.renderImageWithData(data.renderDataWithSize(size))
				}

				func getImageForData(_ data: TestData, _ size: CGSize) -> ImageResult? {
					return try? getProducerForData(data, size)
						.single()?
                        .get()
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
					guard let image1 = try? result1.single()?.get().image else { XCTFail("Failed to produce image"); return }
					guard let image2 = try? result2.single()?.get().image else { XCTFail("Failed to produce image"); return }

					expect(image1) === image2
				}
			}

			context("Cache hit") {
				typealias InnerRendererType = AnyRenderer<TestRenderData, ImageResult, Never>
				typealias RenderType = MulticastedRenderer<InnerRendererType, TestRenderData>

				var scheduler: TestScheduler!
				let delay: TimeInterval = 1
                let interval: DispatchTimeInterval = .seconds(Int(delay))

				var innerRenderer: InnerRendererType!
				var renderer: RenderType!

				var cacheHitRenderer: CacheHitRenderer!


				func getProducerForData(_ data: TestData, _ size: CGSize) -> SignalProducer<ImageResult, Never> {
					return renderer.renderImageWithData(data.renderDataWithSize(size))
				}

				func getImageForData(_ data: TestData, _ size: CGSize) -> ImageResult? {
					return try? getProducerForData(data, size)
						.single()?
						.get()
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

					producer.startWithValues { result = $0 }

					scheduler.advance(by: interval)

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
					scheduler.advance(by: interval)

					var result: ImageResult?
					producer.startWithValues { result = $0 }

					expect(result).toEventuallyNot(beNil())
					expect(result?.cacheHit) == true
				}
			}
		}
	}
}

/// `RendererType` decorator that returns `RenderResult` values with
/// `cacheHit` set to whatever the value of `shouldCacheHit` is at a given time.
private final class CacheHitRenderer: RendererType {
	var shouldCacheHit: Bool = false

	private let testRenderer = TestRenderer()

	func renderImageWithData(_ data: TestRenderData) ->  SignalProducer<ImageResult, Never> {
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
	private let delay: TimeInterval
	private let scheduler: DateScheduler

	init(renderer: T, delay: TimeInterval, scheduler: DateScheduler) {
		self.renderer = renderer
		self.delay = delay
		self.scheduler = scheduler
	}

	func renderImageWithData(_ data: T.Data) -> SignalProducer<T.RenderResult, T.Error> {
		return renderer
			.renderImageWithData(data)
			.delay(self.delay, on: self.scheduler)
	}
}
