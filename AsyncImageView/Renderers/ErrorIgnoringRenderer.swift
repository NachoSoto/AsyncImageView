//
//  ErrorIgnoringRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/28/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveCocoa
import Result

/// `RendererType` decorator that ignores errors from a renderer.
/// Note: it's recommended to use `FallbackRenderer` instead, but this is useful,
/// if you're already providing a placeholder renderer.
public final class ErrorIgnoringRenderer<Renderer: RendererType>: RendererType {
	private let renderer: Renderer

	public init(renderer: Renderer) {
		self.renderer = renderer
	}

	public func renderImageWithData(_ data: Renderer.Data) -> SignalProducer<Renderer.RenderResult, NoError> {
		return self.renderer
			.renderImageWithData(data)
			.flatMapError { _ in
				return .empty
			}
	}
}

extension RendererType {
	/// Returns a new `RendererType` that will ignore any errors emitted by the receiver.
	public func ignoreErrors() -> ErrorIgnoringRenderer<Self> {
		return ErrorIgnoringRenderer(renderer: self)
	}
}
