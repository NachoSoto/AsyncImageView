//
//  ContextRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import CoreGraphics
import ReactiveCocoa

/// `SynchronousRendererType` which generates a `UIImage` by rendering into a context.
public final class ContextRenderer<Data: RenderDataType>: SynchronousRendererType {
	public typealias Block = (_ context: CGContext, _ data: Data) -> ()

	private let scale: CGFloat
	private let opaque: Bool
	private let renderingBlock: Block

	/// - opaque: A Boolean flag indicating whether the bitmap is opaque. 
	/// If you know the bitmap is fully opaque, specify YES to ignore the 
	/// alpha channel and optimize the bitmap’s storage.
	public init(scale: CGFloat, opaque: Bool, renderingBlock: Block) {
		self.scale = scale
		self.opaque = opaque
		self.renderingBlock = renderingBlock
	}

	public func renderImageWithData(_ data: Data) -> UIImage {
		// TODO: use new ImageRenderer

		UIGraphicsBeginImageContextWithOptions(data.size, self.opaque, self.scale)

		self.renderingBlock(context: UIGraphicsGetCurrentContext()!, data: data)

		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return image!
	}
}
