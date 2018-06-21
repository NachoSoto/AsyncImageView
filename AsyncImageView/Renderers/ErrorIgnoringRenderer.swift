//
//  ErrorIgnoringRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/28/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift
import Result

/// `RendererType` decorator that ignores errors from a renderer.
/// Note: it's recommended to use `FallbackRenderer` instead, but this is useful,
/// if you're already providing a placeholder renderer.
public final class ErrorIgnoringRenderer<Renderer: RendererType>: RendererType {
	private let renderer: Renderer
    private let handler: ((Renderer.Error) -> ())?

	public init(renderer: Renderer, handler: ((Renderer.Error) -> ())?) {
		self.renderer = renderer
        self.handler = handler
	}

	public func renderImageWithData(_ data: Renderer.Data) -> SignalProducer<Renderer.RenderResult, NoError> {
		return self.renderer
			.renderImageWithData(data)
			.flatMapError { [handler = self.handler] error in
                handler?(error)
                
				return .empty
			}
	}
}

extension RendererType {
	/// Returns a new `RendererType` that will ignore any errors emitted by the receiver.
	public func ignoreErrors() -> ErrorIgnoringRenderer<Self> {
        return ErrorIgnoringRenderer(renderer: self, handler: nil)
	}
    
    /// Returns a new `RendererType` that will ignore any errors emitted by the receiver.
    public func logAndIgnoreErrors(handler: @escaping (Self.Error) -> ()) -> ErrorIgnoringRenderer<Self> {
        return ErrorIgnoringRenderer(renderer: self, handler: handler)
    }
}
