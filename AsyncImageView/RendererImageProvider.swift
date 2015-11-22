//
//  RendererImageProvider.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import Foundation
import ReactiveCocoa

// The initial value is `nil`.
private typealias ImageProperty = AnyProperty<UIImage?>

public final class RendererImageProvider<
	RenderData: RenderDataType,
	Renderer: RendererType
	where Renderer.RenderData == RenderData
>: ImageProviderType {
	// TODO: make this pluggable so that we can make the cache be on disk.
	private let cache: TypedCache<RenderData, CachedImageRenderOperation>

	private let renderer: Renderer

	public init(name: String, renderer: Renderer) {
		self.cache = TypedCache(cacheName: name)
		self.renderer = renderer
	}

	public func getImageForData(data: RenderData) -> SignalProducer<RenderResult, NoError> {
		let property = getPropertyForData(data)

		let image = property.producer
			.filter { $0 != nil } // Skip initial `nil` value.
			.map { $0! }

		let cacheHit: SignalProducer<Bool, NoError> = SignalProducer(values: [
			SignalProducer(value: true),
			SignalProducer(value: false).delay(0.01, onScheduler: QueueScheduler()) // TODO(nacho) STOPSHIP: this isn't very reliable
			])
			.flatten(.Concat)

		return image.combineLatestWith(cacheHit)
			.take(1) // Don't wait for more values.
			.map(RenderResult.init)
			.startOn(QueueScheduler())
			.observeOn(UIScheduler())
	}

	private func getPropertyForData(data: RenderData) -> ImageProperty {
		if let operation = cachedOperation(data) {
			return operation.property
		}

		let property = ImageProperty(
			initialValue: nil,
			producer: renderer.createProducerForRenderingData(data).map(Optional.init)
		)
		cacheProperty(property, forData: data)

		return property
	}

	private func cachedOperation(data: RenderData) -> CachedImageRenderOperation? {
		return cache.valueForKey(data)
	}

	private func cacheProperty(property: ImageProperty, forData data: RenderData) {
		cache.setValue(CachedImageRenderOperation(property: property), forKey: data)
	}
}

extension RendererType {
	private func createProducerForRenderingData(data: RenderData) -> SignalProducer<UIImage, NoError> {
		return SignalProducer { observer, disposable in
			if !disposable.disposed {
				observer.sendNext(self.renderImageWithData(data))
				observer.sendCompleted()
			} else {
				observer.sendInterrupted()
			}
			}
			.startOn(QueueScheduler())
	}
}

private final class CachedImageRenderOperation: NSObject {
	private let property: ImageProperty

	init(property: ImageProperty) {
		self.property = property
	}
}
