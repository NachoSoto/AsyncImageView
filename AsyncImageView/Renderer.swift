//
//  Renderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

/// Information required to produce an image
public protocol RenderDataType: Hashable {
	var size: CGSize { get }
}

public protocol RendererType {
	typealias RenderData: RenderDataType

	func renderImageWithData(data: RenderData) -> UIImage
}

public struct RenderResult {
	let image: UIImage
	let cacheHit: Bool
}
