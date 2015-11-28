//
//  MulticastedRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa

// The initial value is `nil`.
private typealias ImageProperty = AnyProperty<ImageResult?>

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
	private let cache: Atomic<InMemoryCache<Data, ImageProperty>>

	public init(renderer: Renderer, name: String) {
		self.renderer = renderer
		self.cache = Atomic(InMemoryCache(cacheName: name))
	}

	public func renderImageWithData(data: Data) -> SignalProducer<ImageResult, NoError> {
		let property = getPropertyForData(data)

		return property.producer
			.filter { $0 != nil } // Skip initial `nil` value.
			.map { $0! }
			.take(1)
 	}

	private func getPropertyForData(data: Data) -> ImageProperty {
		return self.cache.withValue { (cache) -> ImageProperty in
			if let property = cache.valueForKey(data) {
				return property
			}

			let property = ImageProperty(
				initialValue: nil,
				producer: renderer.createProducerForRenderingData(data)
					.map(Optional.init)
			)
			cache.setValue(property, forKey: data)

			return property
		}
	}
}

extension RendererType where Error == NoError {
	/// Multicasts the results of this `RendererType`.
	public func multicasted(name: String = "com.asyncimageview.multicasting") -> MulticastedRenderer<Self.Data, Self> {
		return MulticastedRenderer(renderer: self, name: name)
	}
}

extension RendererType {
	private func createProducerForRenderingData(data: Data) -> SignalProducer<ImageResult, Error> {
		return self.renderImageWithData(data)
			.flatMap(.Concat) { result in
				return SignalProducer(values: [
					ImageResult(image: result.image, cacheHit: result.cacheHit),
					ImageResult(image: result.image, cacheHit: true)
				])
		}
	}
}
