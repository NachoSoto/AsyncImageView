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

/// `RendererType` decorator which guarantees that images for a given `RenderDataType`
/// are only rendered once, and multicasted to every observer.
public final class MulticastedRenderer<
	Renderer: RendererType,
    Data: RenderDataType
>: RendererType
	where
	Renderer.Data == Data,
	Renderer.Error == Never
{
	private let renderer: Renderer
	private let cache: Atomic<[Data : ImageProperty]>

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
				result = ImageProperty(
					initial: nil,
					then: renderer.createProducerForRenderingData(data)
						.map(Optional.init)
				)

				cache[data] = result
			}
		}

		return result
	}

    #if !os(watchOS)
	private static func clearCacheOnMemoryWarning(_ cache: Atomic<[Data : ImageProperty]>) -> Disposable {
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
                return SignalProducer([
					ImageResult(image: result.image, cacheHit: false),
					ImageResult(image: result.image, cacheHit: true)
				])
		}
	}
}
