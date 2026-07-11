//
//  CacheRendererSpec.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 7/10/26.
//  Copyright © 2026 Nacho Soto. All rights reserved.
//

import Quick
import Nimble
import UIKit

@testable import AsyncImageView

class CacheRendererSpec: QuickSpec {
	override class func spec() {
		describe("CacheRenderer") {
			it("does not cache the original image after inflation fails") {
				let data = TestRenderData(
					data: .a,
					size: CGSize(width: 20, height: 30)
				)
				let sourceRenderer = TestRenderer()
				let cache = InMemoryCache<TestRenderData, ImageResult>(cacheName: #function)
				var shouldFailContextCreation = true

				let renderer = ImageInflaterRenderer(
					renderer: sourceRenderer,
					screenScale: 2,
					opaque: false,
					bitmapContextFactory: { width, height, bytesPerRow, colorSpace, bitmapInfo in
						guard !shouldFailContextCreation else { return nil }

						return UIImage.makeBitmapContext(
							width: width,
							height: height,
							bytesPerRow: bytesPerRow,
							colorSpace: colorSpace,
							bitmapInfo: bitmapInfo
						)
					}
				)
				.withCache(cache)

				let fallbackResult = renderer.renderImageWithData(data).single()?.get()

				expect(fallbackResult?.image.scale) == data.data.rawValue
				expect(fallbackResult?.shouldCache) == false
				expect(cache.valueForKey(data)).to(beNil())
				expect(sourceRenderer.renderedImages.value.count) == 1

				shouldFailContextCreation = false

				let inflatedResult = renderer.renderImageWithData(data).single()?.get()

				expect(inflatedResult?.image.scale) == 2
				expect(inflatedResult?.shouldCache) == true
				expect(cache.valueForKey(data)).toNot(beNil())
				expect(sourceRenderer.renderedImages.value.count) == 2

				let cachedResult = renderer.renderImageWithData(data).single()?.get()

				expect(cachedResult?.cacheHit) == true
				expect(sourceRenderer.renderedImages.value.count) == 2
			}

			it("does not cache the original image after processing output creation fails") {
				let data = TestRenderData(
					data: .a,
					size: CGSize(width: 20, height: 30)
				)
				let sourceRenderer = TestRenderer()
				let cache = InMemoryCache<TestRenderData, ImageResult>(cacheName: #function)
				var shouldFailImageCreation = true

				let renderer = ImageProcessingRenderer(
					renderer: sourceRenderer,
					scale: 2,
					opaque: false,
					renderingBlock: { _, _, _, _, imageDrawing in
						imageDrawing()
					},
					bitmapImageFactory: { context in
						guard !shouldFailImageCreation else { return nil }

						return context.makeImage()
					}
				)
				.withCache(cache)

				let fallbackResult = renderer.renderImageWithData(data).single()?.get()

				expect(fallbackResult?.image.scale) == data.data.rawValue
				expect(fallbackResult?.shouldCache) == false
				expect(cache.valueForKey(data)).to(beNil())
				expect(sourceRenderer.renderedImages.value.count) == 1

				shouldFailImageCreation = false

				let processedResult = renderer.renderImageWithData(data).single()?.get()

				expect(processedResult?.image.scale) == 2
				expect(processedResult?.shouldCache) == true
				expect(cache.valueForKey(data)).toNot(beNil())
				expect(sourceRenderer.renderedImages.value.count) == 2

				let cachedResult = renderer.renderImageWithData(data).single()?.get()

				expect(cachedResult?.cacheHit) == true
				expect(sourceRenderer.renderedImages.value.count) == 2
			}
		}
	}
}
