//
//  ImageProvider.swift
//  ChessWatchApp
//
//  Created by Nacho Soto on 9/17/15.
//  Copyright © 2015 Javier Soto. All rights reserved.
//

import Foundation
import ReactiveCocoa

/// Information required to produce an image
public protocol RenderDataType: Hashable {
	var size: CGSize { get }
}

public protocol RendererType {
	typealias RenderData: RenderDataType

	func renderImageWithData(data: RenderData) -> UIImage
}

public protocol ImageProviderType {
	typealias RenderData: RenderDataType

	func getImageForData(data: RenderData) -> SignalProducer<RenderResult, NoError>
}

public struct RenderResult {
	let image: UIImage
	let cacheHit: Bool
}

// The initial value is `nil`.
private typealias ImageProperty = AnyProperty<UIImage?>

public final class ImageProvider<
	RenderData: RenderDataType,
	Renderer: RendererType
	where Renderer.RenderData == RenderData
>: ImageProviderType {
	// TODO(nacho) STOPSHIP: make this pluggable so that we can make
	// the cache be on disk for TournamentBackgroundView
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
		return cache.objectForKey(data)
	}

	private func cacheProperty(property: ImageProperty, forData data: RenderData) {
		cache.setObject(CachedImageRenderOperation(property: property), forKey: data)
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
