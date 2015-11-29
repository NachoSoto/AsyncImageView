//
//  ImageInflaterRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa

/// `RendererType` decorator that inflates images.
public final class ImageInflaterRenderer<
	Data: RenderDataType, RenderResult: RenderResultType, Error: ErrorType
>: RendererType {
	private let screenScale: CGFloat
	private let opaque: Bool
	private let renderBlock: (Data) -> SignalProducer<RenderResult, Error>

	public init<
		Renderer: RendererType where Renderer.Data == Data, Renderer.RenderResult == RenderResult, Renderer.Error == Error
		>(renderer: Renderer, screenScale: CGFloat, opaque: Bool)
	{
		self.screenScale = screenScale
		self.opaque = opaque
		self.renderBlock = renderer.renderImageWithData
	}

	public func renderImageWithData(data: Data) -> SignalProducer<UIImage, Error> {
		return self.renderBlock(data)
			.map { [scale = self.screenScale] result in
				return result.image.inflate(withSize: data.size, scale: scale, opaque: self.opaque)
			}
			.startOn(QueueScheduler())
	}
}

extension UIImage {
	internal func inflate(withSize size: CGSize, scale: CGFloat, opaque: Bool) -> UIImage {
		assert(size.width > 0 && size.height > 0, "Invalid size: (\(size.width)x\(size.height))")

		let renderSize = CGSize(
			width: size.width * scale,
			height: size.height * scale
		)
		let imageSize = CGSize(
			width: self.size.width * self.scale,
			height: self.size.height * self.scale
		)
		let outputFrame = InflaterSizeCalculator.drawingRectForRenderingImageOfSize(
			imageSize: imageSize,
			inSize: renderSize
		)

		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let alphaInfo: CGImageAlphaInfo = (opaque) ? .NoneSkipLast : .PremultipliedLast
		let bitmapInfo = alphaInfo.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue

		let imageWidth = Int(renderSize.width)
		let imageHeight = Int(renderSize.height)

		let bitmapContext = CGBitmapContextCreate(nil, imageWidth, imageHeight, 8, imageWidth * 4, colorSpace, bitmapInfo)

		guard let imageRef = self.CGImage else { fatalError("Unable to get a CGImage from \(self).") }
		CGContextDrawImage(bitmapContext, outputFrame, imageRef)

		return UIImage(
			CGImage: CGBitmapContextCreateImage(bitmapContext)!,
			scale: scale,
			orientation: self.imageOrientation
		)
	}
}

extension RendererType {
	public func inflatedWithScale(screenScale: CGFloat, opaque: Bool) -> ImageInflaterRenderer<Self.Data, Self.RenderResult, Self.Error> {
		return ImageInflaterRenderer(renderer: self, screenScale: screenScale, opaque: opaque)
	}
}

internal struct InflaterSizeCalculator {
	static func drawingRectForRenderingImageOfSize(imageSize imageSize: CGSize, inSize canvasSize: CGSize) -> CGRect {
		if (imageSize == canvasSize ||
			abs(imageSize.aspectRatio - canvasSize.aspectRatio) < CGFloat(FLT_EPSILON)) {
				return CGRect(origin: CGPointZero, size: canvasSize)
		} else {
			let destScale = max(
				canvasSize.width / imageSize.width,
				canvasSize.height / imageSize.height
			)

			let newWidth = imageSize.width * destScale
			let newHeight = imageSize.height * destScale

			let dWidth = ((canvasSize.width - newWidth) / 2.0)
			let dHeight = ((canvasSize.height - newHeight) / 2.0)

			return CGRectMake(dWidth, dHeight, newWidth, newHeight)
		}
	}
}

private extension CGSize {
	var aspectRatio: CGFloat {
		return self.width / self.height
	}
}
