//
//  CacheRendererSpec.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 7/10/26.
//  Copyright © 2026 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift
import Testing

@testable import AsyncImageView

@Suite
struct CacheRendererTests {
	private let fixture = CacheFailureFixture()

	@Test
	func failedInflationIsNotCached() {
		var shouldFail = true
		let renderer = ImageInflaterRenderer(
			renderer: self.fixture.sourceRenderer,
			screenScale: 2,
			opaque: false,
			bitmapContextFactory: { width, height, bytesPerRow, colorSpace, bitmapInfo in
				guard !shouldFail else { return nil }

				return UIImage.makeBitmapContext(
					width: width,
					height: height,
					bytesPerRow: bytesPerRow,
					colorSpace: colorSpace,
					bitmapInfo: bitmapInfo
				)
			}
		)
		.withCache(self.fixture.cache)

		self.fixture.verifyFailureThenSuccess(renderer: renderer) {
			shouldFail = false
		}
	}

	@Test
	func failedProcessingOutputIsNotCached() {
		var shouldFail = true
		let renderer = ImageProcessingRenderer(
			renderer: self.fixture.sourceRenderer,
			scale: 2,
			opaque: false,
			renderingBlock: { _, _, _, _, imageDrawing in
				imageDrawing()
			},
			bitmapImageFactory: { context in
				guard !shouldFail else { return nil }

				return context.makeImage()
			}
		)
		.withCache(self.fixture.cache)

		self.fixture.verifyFailureThenSuccess(renderer: renderer) {
			shouldFail = false
		}
	}
}

private final class CacheFailureFixture {
	let data = TestRenderData(
		data: .a,
		size: CGSize(width: 20, height: 30)
	)
	let sourceRenderer = TestRenderer()
	let cache = InMemoryCache<TestRenderData, ImageResult>(cacheName: #file)

	func verifyFailureThenSuccess<Renderer: RendererType>(
		renderer: Renderer,
		enableSuccessfulRendering: () -> Void
	) where
		Renderer.Data == TestRenderData,
		Renderer.RenderResult == ImageResult,
		Renderer.Error == Never {
		let fallbackResult = renderer.renderImageWithData(self.data).single()?.get()

		#expect(fallbackResult?.image.scale == self.data.data.rawValue)
		#expect(fallbackResult?.shouldCache == false)
		#expect(self.cache.valueForKey(self.data) == nil)
		#expect(self.sourceRenderer.renderedImages.value.count == 1)

		enableSuccessfulRendering()

		let processedResult = renderer.renderImageWithData(self.data).single()?.get()

		#expect(processedResult?.image.scale == 2)
		#expect(processedResult?.shouldCache == true)
		#expect(self.cache.valueForKey(self.data) != nil)
		#expect(self.sourceRenderer.renderedImages.value.count == 2)

		let cachedResult = renderer.renderImageWithData(self.data).single()?.get()

		#expect(cachedResult?.cacheHit == true)
		#expect(self.sourceRenderer.renderedImages.value.count == 2)
	}
}
