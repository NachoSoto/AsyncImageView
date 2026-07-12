import Foundation
import Testing
import UIKit

import ReactiveSwift

@testable import AsyncImageView

@Suite
struct DiskCacheImageScaleTests {
	@Test
	func preservesImageScaleAndDimensions() throws {
		let cache = DiskCache<ImageCacheKey, UIImage>(rootDirectory: temporaryDirectory())
		let image = makeImage(size: CGSize(width: 44, height: 44), scale: 2)
		let key = ImageCacheKey(uniqueFilename: "image", size: image.size)

		cache.setValue(image, forKey: key)
		let restored = try #require(cache.valueForKey(key))

		#expect(restored.size == image.size)
		#expect(restored.scale == image.scale)
		#expect(restored.cgImage?.width == image.cgImage?.width)
		#expect(restored.cgImage?.height == image.cgImage?.height)
	}

	@Test
	func preservesScaleThroughACachedRendererHit() throws {
		let cache = DiskCache<ImageCacheKey, ImageResult>(rootDirectory: temporaryDirectory())
		let image = makeImage(size: CGSize(width: 52, height: 52), scale: 3)
		let key = ImageCacheKey(uniqueFilename: "result", size: image.size)
		let source = ScaleImageRenderer(image: image)
		let renderer = source.withCache(cache)

		let rendered = try #require(renderer.renderImageWithData(key).single()?.get())
		let restored = try #require(renderer.renderImageWithData(key).single()?.get())

		#expect(source.renderCount == 1)
		#expect(rendered.cacheHit == false)
		#expect(restored.cacheHit == true)
		#expect(restored.image.size == image.size)
		#expect(restored.image.scale == image.scale)
		#expect(restored.image.cgImage?.width == image.cgImage?.width)
		#expect(restored.image.cgImage?.height == image.cgImage?.height)
	}

	@Test
	func regeneratesLegacyRawPNGEntries() throws {
		let directory = temporaryDirectory()
		let cache = DiskCache<ImageCacheKey, ImageResult>(rootDirectory: directory)
		let key = ImageCacheKey(uniqueFilename: "legacy", size: CGSize(width: 44, height: 44))
		let image = makeImage(size: CGSize(width: 44, height: 44), scale: 2)
		let source = ScaleImageRenderer(image: image)
		let renderer = source.withCache(cache)
		let data = try #require(image.pngData())
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
		try data.write(to: directory.appendingPathComponent(key.uniqueFilename))

		let regenerated = try #require(renderer.renderImageWithData(key).single()?.get())
		let cached = try #require(renderer.renderImageWithData(key).single()?.get())

		#expect(source.renderCount == 1)
		#expect(regenerated.cacheHit == false)
		#expect(cached.cacheHit == true)
		#expect(cached.image.size == image.size)
		#expect(cached.image.scale == image.scale)
	}

	private func temporaryDirectory() -> URL {
		URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
			.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
	}

	private func makeImage(size: CGSize, scale: CGFloat) -> UIImage {
		let format = UIGraphicsImageRendererFormat()
		format.scale = scale

		return UIGraphicsImageRenderer(size: size, format: format).image { context in
			context.cgContext.setFillColor(UIColor.red.cgColor)
			context.cgContext.fill(CGRect(origin: .zero, size: size))
		}
	}
}

private struct ImageCacheKey: DataFileType {
	let uniqueFilename: String
	let size: CGSize
	let subdirectory: String? = nil
}

extension ImageCacheKey: RenderDataType {}

private final class ScaleImageRenderer: RendererType {
	private let image: UIImage
	private(set) var renderCount = 0

	init(image: UIImage) {
		self.image = image
	}

	func renderImageWithData(_ data: ImageCacheKey) -> SignalProducer<ImageResult, Never> {
		self.renderCount += 1

		return SignalProducer(value: ImageResult(image: self.image, cacheHit: false))
	}
}
