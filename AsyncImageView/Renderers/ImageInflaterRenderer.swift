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
	Data: RenderDataType, RenderResult: RenderResultType, Error: Swift.Error
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

	public func renderImageWithData(_ data: Data) -> SignalProducer<UIImage, Error> {
		return self.renderBlock(data)
			.map { [scale = self.screenScale] result in
				return result.image.inflate(withSize: data.size, scale: scale, opaque: self.opaque)
			}
			.start(on: QueueScheduler())
	}
}

extension UIImage {
	internal func inflate(withSize size: CGSize, scale: CGFloat, opaque: Bool) -> UIImage {
		return self.processImageWithBitmapContext(
			withSize: size,
			scale: scale,
			opaque: opaque,
			renderingBlock: { _, _, _, imageDrawing in
				imageDrawing()
			}
		)
	}

	internal func processImageWithBitmapContext(
		withSize size: CGSize,
		scale: CGFloat,
		opaque: Bool,
		renderingBlock: @noescape(image: UIImage, context: CGContext, contextSize: CGSize, imageDrawing: () -> ()) -> ())
		-> UIImage
	{
		precondition(size.width > 0 && size.height > 0, "Invalid size: \(size.width)x\(size.height)")

		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let alphaInfo: CGImageAlphaInfo = (opaque) ? .noneSkipLast : .premultipliedLast
		let bitmapInfo = alphaInfo.rawValue | CGBitmapInfo.byteOrder32Little.rawValue

		let contextSize = size * scale

		let imageWidth = Int(contextSize.width)
		let imageHeight = Int(contextSize.height)

		guard let bitmapContext = CGContext(data: nil, width: imageWidth, height: imageHeight, bitsPerComponent: 8, bytesPerRow: imageWidth * 4, space: colorSpace, bitmapInfo: bitmapInfo) else {
			fatalError("Error creating bitmap context")
		}

		renderingBlock(
			image: self,
			context: bitmapContext,
			contextSize: contextSize,
			imageDrawing: {
				let outputFrame = InflaterSizeCalculator.drawingRectForRenderingImageOfSize(
					imageSize: self.size * self.scale,
					inSize: contextSize
				)

				guard let imageRef = self.cgImage else { fatalError("Unable to get a CGImage from \(self).") }
				bitmapContext.draw(in: outputFrame, image: imageRef)
			}
		)

		return UIImage(
			cgImage: bitmapContext.makeImage()!,
			scale: scale,
			orientation: self.imageOrientation
		)
	}
}

extension RendererType {
	public func inflatedWithScale(_ screenScale: CGFloat, opaque: Bool) -> ImageInflaterRenderer<Self.Data, Self.RenderResult, Self.Error> {
		return ImageInflaterRenderer(renderer: self, screenScale: screenScale, opaque: opaque)
	}
}

internal struct InflaterSizeCalculator {
	static func drawingRectForRenderingImageOfSize(imageSize: CGSize, inSize canvasSize: CGSize) -> CGRect {
		if (imageSize == canvasSize ||
			abs(imageSize.aspectRatio - canvasSize.aspectRatio) < CGFloat(FLT_EPSILON)) {
				return CGRect(origin: .zero, size: canvasSize)
		} else {
			let destScale = max(
				canvasSize.width / imageSize.width,
				canvasSize.height / imageSize.height
			)

			let newWidth = imageSize.width * destScale
			let newHeight = imageSize.height * destScale

			let dWidth = ((canvasSize.width - newWidth) / 2.0)
			let dHeight = ((canvasSize.height - newHeight) / 2.0)

			return CGRect(x: dWidth, y: dHeight, width: newWidth, height: newHeight)
		}
	}
}

private extension CGSize {
	var aspectRatio: CGFloat {
		return self.width / self.height
	}
}

private func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
	return CGSize(
		width: lhs.width * rhs,
		height: lhs.height * rhs
	)
}
