//
//  Renderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa

/// Information required to produce an image
public protocol RenderDataType: Hashable {
	var size: CGSize { get }
}

public struct RenderResult {
	let image: UIImage
	let cacheHit: Bool
}

public protocol RendererType {
	typealias RenderData: RenderDataType
	typealias Error: ErrorType

	func renderImageWithData(data: RenderData) -> SignalProducer<UIImage, Error>
}

public protocol SynchronousRendererType {
	typealias RenderData: RenderDataType

	func renderImageWithData(data: RenderData) -> UIImage
}
