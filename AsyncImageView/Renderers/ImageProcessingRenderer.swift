//
//  ImageProcessingRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift
import ReactiveCocoa

/// `RendererType` decorator that allows rendering a new image derived from the original one.
public final class ImageProcessingRenderer<Renderer: RendererType>: RendererType {
	public typealias Block = (_ image: UIImage, _ context: CGContext, _ contextSize: CGSize, _ imageDrawingBlock: () -> ()) -> ()

	private let renderer: Renderer
	private let scale: CGFloat
	private let opaque: Bool
	private let renderingBlock: Block

	private let schedulerCreator: () -> SchedulerProtocol

	public init(
		renderer: Renderer,
		scale: CGFloat,
		opaque: Bool,
		renderingBlock: @escaping Block,
		schedulerCreator: @escaping () -> SchedulerProtocol = { QueueScheduler() }) {
			self.renderer = renderer
			self.scale = scale
			self.opaque = opaque
			self.renderingBlock = renderingBlock

			self.schedulerCreator = schedulerCreator
	}

	public func renderImageWithData(_ data: Renderer.Data) -> SignalProducer<UIImage, Renderer.Error> {
		let size = data.size

		return self.renderer.renderImageWithData(data)
			.observe(on: self.schedulerCreator())
			.map { $0.image }
			.map { [scale = self.scale, opaque = self.opaque, block = self.renderingBlock] image in
				image.processImageWithBitmapContext(
					withSize: size,
					scale: scale,
					opaque: opaque,
					renderingBlock: block
				)
			}
	}
}

extension RendererType {
	/// Decorates this `RendererType` by applying the given block to every generated image.
	public func processedWithScale(
		scale: CGFloat,
		opaque: Bool,
		renderingBlock block: @escaping ImageProcessingRenderer<Self>.Block
	) -> ImageProcessingRenderer<Self> {
		return ImageProcessingRenderer(renderer: self, scale: scale, opaque: opaque, renderingBlock: block)
	}
}
