//
//  RendererImageProviderSpec.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import Quick
import Nimble

import Result
import ReactiveCocoa

@testable import AsyncImageView

private typealias ProviderType = RendererImageProvider<TestRenderData, TestRenderer>

class RendererImageProviderSpec: QuickSpec {
	override func spec() {
		fdescribe("RendererImageProvider") {
			var provider: ProviderType!
			var renderer: TestRenderer!

			beforeEach {
				renderer = TestRenderer()
				provider = ProviderType(
					name: "com.nachosoto.provider",
					renderer: renderer
				)
			}

			func getProducerForData(data: TestData, withSize size: CGSize) -> SignalProducer<RenderResult, NoError> {
				return provider.getImageForData(
					data.renderDataWithSize(size),
					scheduler: ImmediateScheduler()
				)
			}

			func getImageForData(data: TestData, withSize size: CGSize) -> RenderResult? {
				return getProducerForData(data, withSize: size)
					.single()?
					.value
			}

			it("produces an image") {
				let data: TestData = .A
				let size = CGSize(width: 10, height: 10)
				let result = getImageForData(data, withSize: size)

				verifyImage(result?.image, withSize: size, data: data)
			}

			it("multicasts rendering") {
				let data: TestData = .A
				let size = CGSize(width: 10, height: 10)

				// Get both producers at the same time.
				let result1 = getProducerForData(data, withSize: size)
				let result2 = getProducerForData(data, withSize: size)

				// Starting the producers should yield the same image.
				let image1 = result1.single()?.value?.image
				let image2 = result2.single()?.value?.image

				expect(image1!) === image2!
			}
		}
	}
}
