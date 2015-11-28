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
private typealias ImageProperty = AnyProperty<RenderResult?>

/// `RendererType` decorator which guarantees that images for a given `RenderDataType`
/// are only rendered once, and multicasted to every observer.
public final class MulticastedRenderer<
	RenderData: RenderDataType,
	Renderer: RendererType
	where
	Renderer.RenderData == RenderData,
	Renderer.Error == NoError
>: RendererType {
	private let renderer: Renderer
	private let cache: InMemoryCache<RenderData, ImageProperty>

	public init(renderer: Renderer, name: String) {
		self.renderer = renderer
		self.cache = InMemoryCache(cacheName: name)
	}

	public func renderImageWithData(data: RenderData) -> SignalProducer<RenderResult, NoError> {
		let property = getPropertyForData(data)

		return property.producer
			.filter { $0 != nil } // Skip initial `nil` value.
			.map { $0! }
			.take(1)
 	}

	private func getPropertyForData(data: RenderData) -> ImageProperty {
		if let operation = cachedOperation(data) {
			return operation
		}

		let property = ImageProperty(
			initialValue: nil,
			producer: renderer.createProducerForRenderingData(data)
				.map(Optional.init)
		)
		cacheProperty(property, forData: data)

		return property
	}

	private func cachedOperation(data: RenderData) -> ImageProperty? {
		return cache.valueForKey(data)
	}

	private func cacheProperty(property: ImageProperty, forData data: RenderData) {
		cache.setValue(property, forKey: data)
	}
}

extension RendererType where Error == NoError {
	/// Multicasts the results of this `RendererType`.
	public func multicasted(name: String = "com.asyncimageview.multicasting") -> MulticastedRenderer<Self.RenderData, Self> {
		return MulticastedRenderer(renderer: self, name: name)
	}
}

extension RendererType {
	private func createProducerForRenderingData(data: RenderData) -> SignalProducer<RenderResult, Error> {
		return self.renderImageWithData(data)
			.flatMap(.Concat) { result in
				return SignalProducer(values: [
					RenderResult(image: result.image, cacheHit: result.cacheHit),
					RenderResult(image: result.image, cacheHit: true)
				])
		}
	}
}
