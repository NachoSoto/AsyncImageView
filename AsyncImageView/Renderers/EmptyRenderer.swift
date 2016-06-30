//
//  EmptyRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/28/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveCocoa
import Result

/// `RendererType` which does not generate any images.
///
/// Useful as a default value for `AsyncImageView`'s placeholder renderer.
public final class EmptyRenderer<
	Data: RenderDataType,
	RenderResult: RenderResultType
>: RendererType {
	public init() {
	}

	public func renderImageWithData(_ data: Data) -> SignalProducer<RenderResult, NoError> {
		return .empty
	}
}
