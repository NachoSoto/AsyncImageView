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

	private let format: UIGraphicsImageRendererFormat
	private let renderingBlock: Block

	/// - opaque: A Boolean flag indicating whether the bitmap is opaque. 
	/// If you know the bitmap is fully opaque, specify YES to ignore the 
	/// alpha channel and optimize the bitmap’s storage.
	public init(scale: CGFloat, opaque: Bool, renderingBlock: @escaping Block) {
		self.format = UIGraphicsImageRendererFormat()
		self.format.opaque = opaque
		self.format.scale = scale
		self.renderingBlock = renderingBlock
	}

	public func renderImageWithData(_ data: Data) -> UIImage {
		let renderer = UIGraphicsImageRenderer(
			size: data.size,
			format: self.format
		)

		return renderer.image { context in
			self.renderingBlock(UIGraphicsGetCurrentContext()!, data)
		}
	}
}
