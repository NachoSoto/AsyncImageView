//
//  LocalImageRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveCocoa
import Result

public protocol LocalRenderDataType: RenderDataType {
	var image: UIImage { get }
}

/// `RendererType` which loads images from the bundle.
///
/// Note that this Renderer will ignore `RenderDataType.size`.
/// Consider chaining this with `ImageInflaterRenderer`.
public final class LocalImageRenderer<T: LocalRenderDataType>: RendererType {
	public init() {

	}

	public func renderImageWithData(data: T) -> SignalProducer<UIImage, NoError> {
		return SignalProducer
			.attempt { Result(data.image) }
			.startOn(QueueScheduler())
	}
}
