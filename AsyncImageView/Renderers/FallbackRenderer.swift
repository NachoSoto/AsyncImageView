//
//  FallbackRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa

/// `RendererType` decorator that will fall back from one `RendererType` to another.
public final class FallbackRenderer<
	Data: RenderDataType,
	RR1: RenderResultType,
	RR2: RenderResultType,
	E1: Swift.Error,
	E2: Swift.Error
>: RendererType {
	private let primaryRenderer: AnyRenderer<Data, RR1, E1>
	private let fallbackRenderer: AnyRenderer<Data, RR2, E2>

	public init<
		R1: RendererType, R2: RendererType
		where
		R1.Data == Data,
		R2.Data == Data,
		R1.RenderResult == RR1,
		R2.RenderResult == RR2,
		R1.Error == E1,
		R2.Error == E2
		>(primaryRenderer: R1, fallbackRenderer: R2)
	{
		self.primaryRenderer = AnyRenderer(primaryRenderer)
		self.fallbackRenderer = AnyRenderer(fallbackRenderer)
	}

	/// The resulting `SignalProducer` will emit images created by the primary
	/// renderer. If that emits an error, the fallback Renderer will be used.
	public func renderImageWithData(_ data: Data) -> SignalProducer<ImageResult, E2> {
		return self.primaryRenderer
			.renderImageWithData(data)
			.map { $0.asResult }
			.flatMapError { [fallback = self.fallbackRenderer] _ in
				return fallback
					.renderImageWithData(data)
					.map { $0.asResult }
			}
	}
}

extension RendererType {
	/// Surrounds this renderer with a layer of caching.
	public func fallback<
		Other: RendererType
		where
		Self.Data == Other.Data
		>(_ fallbackRenderer: Other) -> FallbackRenderer<Self.Data, Self.RenderResult, Other.RenderResult, Self.Error, Other.Error>
	{
		return FallbackRenderer(primaryRenderer: self, fallbackRenderer: fallbackRenderer)
	}
}

extension RenderResultType {
	private var asResult: ImageResult {
		return ImageResult(
			image: self.image,
			cacheHit: self.cacheHit
		)
	}
}

extension ImageResult {
	private var asResult: ImageResult {
		return self
	}
}
