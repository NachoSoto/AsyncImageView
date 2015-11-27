//
//  ImageProcessingRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa

/// `RendererType` decorator that applies processing to every emitted image.
public final class ImageProcessingRenderer<Renderer: RendererType>: RendererType {
	public typealias BlockType = (UIImage) -> UIImage

	private let renderer: Renderer
	private let processingBlock: BlockType

	public init(renderer: Renderer, processingBlock: BlockType) {
		self.renderer = renderer
		self.processingBlock = processingBlock
	}

	public func renderImageWithData(data: Renderer.RenderData) -> SignalProducer<UIImage, Renderer.Error> {
		return self.renderer.renderImageWithData(data)
			.observeOn(QueueScheduler())
			.map { $0.image }
			.map(self.processingBlock)
	}
}
