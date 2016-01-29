//
//  MulticastedRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa

/// `RendererType` decorator which guarantees that images for a given `RenderDataType`
/// are only rendered once, and multicasted to every observer.
public final class MulticastedRenderer<
	Data: RenderDataType,
	Renderer: RendererType
	where
	Renderer.Data == Data,
	Renderer.Error == NoError
>: RendererType {
	private let renderer: Renderer
	private let cache: Atomic<[Data : SignalProducer<ImageResult, NoError>]>

	private let memoryWarningDisposable: Disposable

	public init(renderer: Renderer) {
		self.renderer = renderer
		self.cache = Atomic([:])

		self.memoryWarningDisposable = MulticastedRenderer.clearCacheOnMemoryWarning(self.cache)
	}

	deinit {
		self.memoryWarningDisposable.dispose()
	}

	public func renderImageWithData(data: Data) -> SignalProducer<ImageResult, NoError> {
		var result: SignalProducer<ImageResult, NoError>!

		self.cache.modify { cache in
			var mutableCache = cache

			if let signal = cache[data] {
				result = signal
				return cache
			}

			result = self.createSignalForData(data)

			mutableCache[data] = result
			return mutableCache
		}

		return result
 	}

	private func createSignalForData(data: Data) -> SignalProducer<ImageResult, NoError> {
		return self.renderer
			.createProducerForRenderingData(data)
			.replayLazily(1)
	}

	private static func clearCacheOnMemoryWarning(cache: Atomic<[Data : SignalProducer<ImageResult, NoError>]>) -> Disposable {
		return NSNotificationCenter.defaultCenter()
			.rac_notifications(UIApplicationDidReceiveMemoryWarningNotification, object: nil)
			.observeOn(QueueScheduler())
			.startWithNext { _ in
				cache.modify { _ in [:] }
			}
	}
}

extension RendererType where Error == NoError {
	/// Multicasts the results of this `RendererType`.
	public func multicasted() -> MulticastedRenderer<Self.Data, Self> {
		return MulticastedRenderer(renderer: self)
	}
}

extension RendererType {
	private func createProducerForRenderingData(data: Data) -> SignalProducer<ImageResult, Error> {
		return self.renderImageWithData(data)
			.flatMap(.Concat) { result in
				return SignalProducer(values: [
					ImageResult(image: result.image, cacheHit: false),
					ImageResult(image: result.image, cacheHit: true)
				])
		}
	}
}
