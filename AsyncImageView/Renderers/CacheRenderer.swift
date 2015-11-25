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
public final class CacheRenderer<R: RendererType, C: CacheType
where C.Key == R.RenderData, C.Value == UIImage>: RendererType {
	private let renderer: R
	private let cache: C

	public init(renderer: R, cache: C) {
		self.renderer = renderer
		self.cache = cache
	}

	/// Returns an image from the cache if found,
	/// otherwise it invokes the decorated `renderer` and caches the result.
	public func renderImageWithData(data: R.RenderData) -> SignalProducer<UIImage, R.Error> {
		return SignalProducer
			.attempt { [cache = self.cache] in
				return Result(cache.valueForKey(data), failWith: CacheRendererError.ImageNotFound)
			}
			.startOn(QueueScheduler())
			.flatMapError { [renderer = self.renderer] _ in
				return renderer
					.renderImageWithData(data)
					.on(next: { [cache = self.cache] image in
						cache.setValue(image, forKey: data)
					})
			}
	}
}

private enum CacheRendererError: ErrorType {
	case ImageNotFound
}
