//
//  ImageProcessingRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift

/// `RendererType` decorator that allows rendering a new image derived from the original one.
public final class ImageProcessingRenderer<Renderer: RendererType>: RendererType {
	public typealias Block = (_ image: UIImage, _ context: CGContext, _ contextSize: CGSize, _ data: Renderer.Data, _ imageDrawingBlock: () -> Void) -> Void
	public typealias Data = Renderer.Data
	public typealias Error = Renderer.Error
	public typealias RenderResult = ImageResult

	private let renderer: Renderer
	private let scale: CGFloat
	private let opaque: Bool
	private let contentMode: ImageInflaterRendererContentMode
	private let renderingBlock: Block
	private let bitmapImageFactory: UIImage.BitmapImageFactory

	private let schedulerCreator: () -> Scheduler

	public convenience init(
		renderer: Renderer,
		scale: CGFloat,
		opaque: Bool,
		contentMode: ImageInflaterRendererContentMode = .defaultMode,
		renderingBlock: @escaping Block,
		schedulerCreator: @escaping () -> Scheduler = { QueueScheduler() }) {
		self.init(
			renderer: renderer,
			scale: scale,
			opaque: opaque,
			contentMode: contentMode,
			renderingBlock: renderingBlock,
			bitmapImageFactory: UIImage.makeBitmapImage,
			schedulerCreator: schedulerCreator
		)
	}

	internal init(
		renderer: Renderer,
		scale: CGFloat,
		opaque: Bool,
		contentMode: ImageInflaterRendererContentMode = .defaultMode,
		renderingBlock: @escaping Block,
		bitmapImageFactory: @escaping UIImage.BitmapImageFactory,
		schedulerCreator: @escaping () -> Scheduler = { QueueScheduler() }
	) {
		self.renderer = renderer
		self.scale = scale
		self.opaque = opaque
		self.contentMode = contentMode
		self.renderingBlock = renderingBlock
		self.bitmapImageFactory = bitmapImageFactory

		self.schedulerCreator = schedulerCreator
	}

	public func renderImageWithData(_ data: Data) -> SignalProducer<ImageResult, Error> {
		return self.renderer.renderImageWithData(data)
			.observe(on: self.schedulerCreator())
			.map { [scale = self.scale, opaque = self.opaque, block = self.renderingBlock, contentMode = self.contentMode, bitmapImageFactory = self.bitmapImageFactory] result in
				let processingResult = result.image.processImageWithBitmapContext(
					withSize: data.size,
					scale: scale,
					opaque: opaque,
					contentMode: contentMode,
					bitmapImageFactory: bitmapImageFactory,
					renderingBlock: { image, context, contextSize, imageDrawingBlock in
						block(
							image,
							context,
							contextSize,
							data,
							imageDrawingBlock
						)
					}
				)

				return ImageResult(
					image: processingResult.image,
					cacheHit: result.cacheHit,
					shouldCache: result.shouldCache && processingResult.didProcess
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
