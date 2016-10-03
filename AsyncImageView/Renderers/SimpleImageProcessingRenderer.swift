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
/// This allows, for example, to apply `UIImage.resizableImage(withCapInsets:)` on every image.
public final class SimpleImageProcessingRenderer<Renderer: RendererType>: RendererType {
    public typealias Block = (image: UIImage, data: Renderer.Data) -> UIImage

	private let renderer: Renderer
	private let renderingBlock: Block

	private let schedulerCreator: () -> SchedulerType

	public init(
		renderer: Renderer,
		renderingBlock: Block,
		schedulerCreator: () -> SchedulerType = { QueueScheduler() }
    ) {
        self.renderer = renderer
        self.renderingBlock = renderingBlock
        
        self.schedulerCreator = schedulerCreator
    }

	public func renderImageWithData(data: Renderer.Data) -> SignalProducer<UIImage, Renderer.Error> {
		return self.renderer.renderImageWithData(data)
			.observeOn(self.schedulerCreator())
			.map { $0.image }
			.map { [block = self.renderingBlock] image in
                block(image: image, data: data)
			}
	}
}

extension RendererType {
	/// Decorates this `RendererType` by applying the given block to every generated image.
	public func mapImage(function: SimpleImageProcessingRenderer<Self>.Block) -> SimpleImageProcessingRenderer<Self> {
        return SimpleImageProcessingRenderer(renderer: self, renderingBlock: function)
	}
}
