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
	Cache.Key == Renderer.RenderData,
	Cache.Value == UIImage
>: RendererType {
	private let renderer: Renderer
	private let cache: Cache

	public init(renderer: Renderer, cache: Cache) {
		self.renderer = renderer
		self.cache = cache
	}

	/// Returns an image from the cache if found,
	/// otherwise it invokes the decorated `renderer` and caches the result.
	public func renderImageWithData(data: Renderer.RenderData) -> SignalProducer<RenderResult, Renderer.Error> {
		return SignalProducer
			.attempt { [cache = self.cache] in
				return createResult(
					cache.valueForKey(data)?.asCacheHit,
					failWith: CacheRendererError.ImageNotFound
				)
			}
			.startOn(QueueScheduler())
			.flatMapError { [renderer = self.renderer] _ in
				return renderer
					.renderImageWithData(data)
					.on(next: { [cache = self.cache] result in
						cache.setValue(result.image, forKey: data)
					})
					.map { $0.image.asCacheMiss }
			}
	}
}

extension RendererType {
	/// Surrounds this renderer with a layer of caching.
	public func withCache<
		Cache: CacheType
		where Cache.Key == Self.RenderData, Cache.Value == UIImage
		>(cache: Cache) -> CacheRenderer<Self, Cache>
	{
		return CacheRenderer(renderer: self, cache: cache)
	}
}

private enum CacheRendererError: ErrorType {
	case ImageNotFound
}

// Wrapping initializer to work around `Result` ambiguity.
private func createResult<T, Error: ErrorType>(value: T?, @autoclosure failWith: () -> Error) -> Result<T, Error> {
	return Result(value, failWith: failWith)
}

extension UIImage {
	private var asCacheHit: RenderResult {
		return RenderResult(
			image: self,
			cacheHit: true
		)
	}

	private var asCacheMiss: RenderResult {
		return RenderResult(
			image: self,
			cacheHit: false
		)
	}
}
