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

			func getImageForData(data: TestData, withSize size: CGSize) -> RenderResult? {
				let producer = provider.getImageForData(
					data.renderDataWithSize(size),
					scheduler: ImmediateScheduler()
				)

				return producer
					.single()?
					.value
			}

			it("produces an image") {
				let data: TestData = .A
				let size = CGSize(width: 10, height: 10)
				let result = getImageForData(data, withSize: size)

				verifyImage(result?.image, withSize: size, data: data)
			}
		}
	}
}
