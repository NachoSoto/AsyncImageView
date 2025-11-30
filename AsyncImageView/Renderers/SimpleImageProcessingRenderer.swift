//
//  ImageProcessingRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift

/// `RendererType` decorator that applies processing to every emitted image.
/// This allows, for example, to apply `UIImage.resizableImage(withCapInsets:)` on every image.
public final class SimpleImageProcessingRenderer<Renderer: RendererType>: RendererType
where Renderer.RenderResult: ImageReplacingRenderResultType {
    public typealias Block = (_ image: UIImage, _ data: Renderer.Data) -> UIImage

	private let renderer: Renderer
	private let renderingBlock: Block

	private let schedulerCreator: () -> Scheduler

	public init(
		renderer: Renderer,
		renderingBlock: @escaping Block,
		schedulerCreator: @escaping () -> Scheduler = { QueueScheduler() }
    ) {
        self.renderer = renderer
        self.renderingBlock = renderingBlock
        
        self.schedulerCreator = schedulerCreator
    }

	public func renderImageWithData(_ data: Renderer.Data) -> SignalProducer<Renderer.RenderResult, Renderer.Error> {
		return self.renderer.renderImageWithData(data)
			.observe(on: self.schedulerCreator())
			.map { [block = self.renderingBlock] result in
                let processedImage = block(result.image, data)
                return result.replacingImage(processedImage)
			}
	}
}

extension RendererType {
	/// Decorates this `RendererType` by applying the given block to every generated image.
	public func mapImage(function: @escaping SimpleImageProcessingRenderer<Self>.Block) -> SimpleImageProcessingRenderer<Self>
    where Self.RenderResult: ImageReplacingRenderResultType
    {
        return SimpleImageProcessingRenderer(renderer: self, renderingBlock: function)
	}
}
