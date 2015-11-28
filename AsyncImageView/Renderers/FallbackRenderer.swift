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
public final class FallbackRenderer<Data: RenderDataType, Result: RenderResultType, E1: ErrorType, E2: ErrorType>: RendererType {
	private let primaryRenderer: AnyRenderer<Data, Result, E1>
	private let fallbackRenderer: AnyRenderer<Data, Result, E2>

	public init<
		R1: RendererType, R2: RendererType
		where
		R1.RenderData == Data,
		R2.RenderData == Data,
		R1.Result == Result,
		R2.Result == Result,
		R1.Error == E1,
		R2.Error == E2
		>(primaryRenderer: R1, fallbackRenderer: R2)
	{
		self.primaryRenderer = AnyRenderer(primaryRenderer)
		self.fallbackRenderer = AnyRenderer(fallbackRenderer)
	}

	/// The resulting `SignalProducer` will emit images created by the primary
	/// renderer. If that emits an error, the fallback Renderer will be used.
	public func renderImageWithData(data: Data) -> SignalProducer<Result, E2> {
		return self.primaryRenderer.renderImageWithData(data)
			.flatMapError { [fallback = self.fallbackRenderer] _ in
				return fallback.renderImageWithData(data)
			}
	}
}

infix operator ??? { associativity left precedence 160 }

/// Allows creating FallbackRenderers with: `renderer1 ??? renderer2 ??? renderer3`.
public func ???<
	R1: RendererType, R2: RendererType,
	Result: RenderResultType
	where
	R1.Result == Result,
	R2.Result == Result,
	R1.RenderData == R2.RenderData
	>(primaryRenderer: R1, fallbackRenderer: R2) -> FallbackRenderer<R1.RenderData, Result, R1.Error, R2.Error>
{
	return FallbackRenderer(primaryRenderer: primaryRenderer, fallbackRenderer: fallbackRenderer)
}
