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

private typealias InnerRendererType = AnyRenderer<TestRenderData, UIImage, NoError>
private typealias RenderType = MulticastedRenderer<TestRenderData, InnerRendererType>

class MulticastedRendererSpec: QuickSpec {
	override func spec() {
		describe("MulticastedRenderer") {
			let data: TestData = .A
			let size = CGSize(width: 1, height: 1)

			var testRenderer: TestRenderer!
			var renderer: RenderType!

			beforeEach {
				testRenderer = TestRenderer()
				renderer = RenderType(
					renderer: AnyRenderer(renderer: testRenderer),
					name: "com.nachosoto.renderer"
				)
			}


			func getProducerForData(data: TestData, withSize size: CGSize) -> SignalProducer<RenderResult, NoError> {
				return renderer.renderImageWithData(data.renderDataWithSize(size))
			}

			func getImageForData(data: TestData, withSize size: CGSize) -> RenderResult? {
				return getProducerForData(data, withSize: size)
					.single()?
					.value
			}

			it("produces an image") {
				let result = getImageForData(data, withSize: size)

				verifyImage(result?.image, withSize: size, data: data)
			}

			it("multicasts rendering") {
				// Get both producers at the same time.
				let result1 = getProducerForData(data, withSize: size)
				let result2 = getProducerForData(data, withSize: size)

				// Starting the producers should yield the same image.
				let image1 = result1.single()?.value?.image
				let image2 = result2.single()?.value?.image

				expect(image1!) === image2!
			}

			context("Cache hit") {
				var scheduler: TestScheduler!

				let delay: NSTimeInterval = 1

				beforeEach {
					scheduler = TestScheduler()

					let delayedTestRenderer: InnerRendererType = AnyRenderer(renderer: DelayedRenderer(
						renderer: testRenderer,
						delay: delay,
						scheduler: scheduler
					))

					renderer = RenderType(
						renderer: delayedTestRenderer,
						name: "com.nachosoto.renderer"
					)
				}

				it("does not cache hit the first time") {
					let producer = getProducerForData(data, withSize: size)
					var result: RenderResult?

					producer.startWithNext { result = $0 }

					scheduler.advanceByInterval(delay)

					expect(result).toEventuallyNot(beNil())
					expect(result?.cacheHit) == false
				}

				it("is a cache hit the second time the producer is fetched") {
					let producer = getProducerForData(data, withSize: size)
					scheduler.advanceByInterval(delay)

					var result: RenderResult?
					producer.startWithNext { result = $0 }

					expect(result).toEventuallyNot(beNil())
					expect(result?.cacheHit) == true
				}
			}
		}
	}
}

/// `RendererType` decorator which introduces a delay on the resulting image.
public final class DelayedRenderer<T: RendererType>: RendererType {
	private let renderer: T
	private let delay: NSTimeInterval
	private let scheduler: DateSchedulerType

	public init(renderer: T, delay: NSTimeInterval, scheduler: DateSchedulerType) {
		self.renderer = renderer
		self.delay = delay
		self.scheduler = scheduler
	}

	public func renderImageWithData(data: T.RenderData) -> SignalProducer<T.Result, T.Error> {
		return renderer
			.renderImageWithData(data)
			.delay(self.delay, onScheduler: self.scheduler)
	}
}
