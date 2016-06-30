//
//  CacheRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Result

/// Decorates a `RendererType` to introduce a layer of caching.
public final class CacheRenderer<
	Renderer: RendererType,
	Cache: CacheType
	where
	Cache.Key == Renderer.Data,
	Cache.Value == Renderer.RenderResult
>: RendererType {
	private let renderer: Renderer
	private let cache: Cache

	public init(renderer: Renderer, cache: Cache) {
		self.renderer = renderer
		self.cache = cache
	}

	/// Returns an image from the cache if found,
	/// otherwise it invokes the decorated `renderer` and caches the result.
	public func renderImageWithData(_ data: Renderer.Data) -> SignalProducer<ImageResult, Renderer.Error> {
		return SignalProducer
			.attempt { [cache = self.cache] in
				return Result(
					cache.valueForKey(data)?.image.asCacheHit,
					failWith: CacheRendererError.imageNotFound
				)
			}
			.start(on: QueueScheduler())
			.flatMapError { [renderer = self.renderer] _ in
				return renderer
					.renderImageWithData(data)
					.on(next: { [cache = self.cache] result in
						cache.setValue(result, forKey: data)
					})
					.map { $0.image.asCacheMiss }
			}
	}
}

extension RendererType {
	/// Surrounds this renderer with a layer of caching.
	public func withCache<
		Cache: CacheType
		where
		Cache.Key == Self.Data,
		Cache.Value == Self.RenderResult
		>(_ cache: Cache) -> CacheRenderer<Self, Cache>
	{
		return CacheRenderer(renderer: self, cache: cache)
	}
}

extension RenderDataType where Self: DataFileType {
	/// The default subdirectory for `RenderDataType`s that
	/// implement `DataFileType` is its size.
	///
	/// This can be overriden to return `nil`.
	public var subdirectory: String? {
		return subdirectoryForSize(self.size)
	}
}

internal func subdirectoryForSize(_ size: CGSize) -> String {
	return String(format: "%.2fx%.2f", size.width, size.height)
}

private enum CacheRendererError: ErrorProtocol {
	case imageNotFound
}

private extension UIImage {
	var asCacheHit: ImageResult {
		return ImageResult(
			image: self,
			cacheHit: true
		)
	}

	var asCacheMiss: ImageResult {
		return ImageResult(
			image: self,
			cacheHit: false
		)
	}
}

