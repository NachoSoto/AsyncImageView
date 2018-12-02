//
//  FallbackRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift

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

	public init<R1: RendererType, R2: RendererType>(primaryRenderer: R1, fallbackRenderer: R2)
		where
		R1.Data == Data,
		R2.Data == Data,
		R1.RenderResult == RR1,
		R2.RenderResult == RR2,
		R1.Error == E1,
		R2.Error == E2
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
	/// Uses the given `RendererType` whenever `self` produces an error.
	public func fallback<Other: RendererType>
		(_ fallbackRenderer: Other) -> FallbackRenderer<Self.Data, Self.RenderResult, Other.RenderResult, Self.Error, Other.Error>
		where Self.Data == Other.Data
	{
		return FallbackRenderer(primaryRenderer: self, fallbackRenderer: fallbackRenderer)
	}
}

extension RenderResultType {
	fileprivate var asResult: ImageResult {
		return ImageResult(
			image: self.image,
			cacheHit: self.cacheHit
		)
	}
}

extension ImageResult {
	fileprivate var asResult: ImageResult {
		return self
	}
}
