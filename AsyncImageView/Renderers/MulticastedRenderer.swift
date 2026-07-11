//
//  MulticastedRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift

// The initial value is `nil`.
private typealias ImageProperty = Property<ImageResult?>

private final class WeakImagePropertyReference {
	weak var value: ImageProperty?
}

private struct ImagePropertyEvictionState {
	let propertyReference = WeakImagePropertyReference()
	var shouldEvict = false
}

/// `RendererType` decorator which guarantees that images for a given `RenderDataType`
/// are only rendered once, and multicasted to every observer.
public final class MulticastedRenderer<
	Renderer: RendererType,
    Data: RenderDataType
>: RendererType
	where
	Renderer.Data == Data,
	Renderer.Error == Never {
	private let renderer: Renderer
	private let cache: Atomic<[Data: ImageProperty]>

    #if !os(watchOS)
	private let memoryWarningDisposable: Disposable
    #endif

	public init(renderer: Renderer) {
		self.renderer = renderer
		self.cache = Atomic([:])

        #if !os(watchOS)
		self.memoryWarningDisposable = MulticastedRenderer.clearCacheOnMemoryWarning(self.cache)
        #endif
	}

	deinit {
        #if !os(watchOS)
		self.memoryWarningDisposable.dispose()
        #endif
	}

	public func renderImageWithData(_ data: Data) -> SignalProducer<ImageResult, Never> {
		let property = getPropertyForData(data)

		return property.producer
			.filter { $0 != nil } // Skip initial `nil` value.
			.map { $0! }
			.take(first: 1)
 	}

	private func getPropertyForData(_ data: Data) -> ImageProperty {
		var result: ImageProperty!

		self.cache.modify { cache in
			if let property = cache[data] {
				result = property
			} else {
				let evictionState = Atomic(ImagePropertyEvictionState())
				let producer = renderer.createProducerForRenderingData(data)
					.on(value: { [propertyCache = self.cache] result in
						guard !result.shouldCache else { return }

						var property: ImageProperty?

						evictionState.modify { state in
							state.shouldEvict = true
							property = state.propertyReference.value
						}

						guard let property = property else { return }

						propertyCache.modify { cache in
							if cache[data] === property {
								cache.removeValue(forKey: data)
							}
						}
					})

				result = ImageProperty(
					initial: nil,
					then: producer.map(Optional.init)
				)

				cache[data] = result

				let shouldEvict = evictionState.modify { state -> Bool in
					state.propertyReference.value = result

					return state.shouldEvict
				}

				if shouldEvict {
					cache.removeValue(forKey: data)
				}
			}
		}

		return result
	}

    #if !os(watchOS)
	private static func clearCacheOnMemoryWarning(_ cache: Atomic<[Data: ImageProperty]>) -> Disposable {
		return NotificationCenter.default
			.reactive.notifications(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil)
			.observe(on: QueueScheduler())
			.observeValues { _ in
				cache.modify { $0 = [:] }
			}!
	}
    #endif
}

extension RendererType where Error == Never {
	/// Multicasts the results of this `RendererType`.
	public func multicasted() -> MulticastedRenderer<Self, Self.Data> {
		return MulticastedRenderer(renderer: self)
	}
}

extension RendererType {
	fileprivate func createProducerForRenderingData(_ data: Data) -> SignalProducer<ImageResult, Error> {
		return self.renderImageWithData(data)
			.flatMap(.concat) { result in
				let cacheMiss = ImageResult(
					image: result.image,
					cacheHit: false,
					shouldCache: result.shouldCache
				)

				guard result.shouldCache else { return SignalProducer(value: cacheMiss) }

				return SignalProducer([
					cacheMiss,
					ImageResult(image: result.image, cacheHit: true, shouldCache: true)
				])
		}
	}
}
