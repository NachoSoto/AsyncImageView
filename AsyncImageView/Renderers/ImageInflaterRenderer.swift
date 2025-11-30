//
//  ImageInflaterRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift

/// `RendererType` decorator that inflates images.
public final class ImageInflaterRenderer<
	Data: RenderDataType, RenderResult: ImageReplacingRenderResultType, Error: Swift.Error
>: RendererType {
    public typealias ContentMode = ImageInflaterRendererContentMode
    
    private let screenScale: CGFloat
	private let opaque: Bool
	private let renderBlock: (Data) -> SignalProducer<RenderResult, Error>
    private let contentMode: ContentMode

    public init<Renderer: RendererType>(
        renderer: Renderer,
        screenScale: CGFloat,
        opaque: Bool,
        contentMode: ContentMode = .defaultMode
    ) where Renderer.Data == Data, Renderer.RenderResult == RenderResult, Renderer.Error == Error {
		self.screenScale = screenScale
		self.opaque = opaque
		self.renderBlock = renderer.renderImageWithData
        self.contentMode = contentMode
	}

	public func renderImageWithData(_ data: Data) -> SignalProducer<RenderResult, Error> {
		return self.renderBlock(data)
			.map { [scale = self.screenScale] result in
                let inflatedImage = result.image.inflate(withSize: data.size,
                                                         scale: scale,
                                                         opaque: self.opaque,
                                                         contentMode: self.contentMode)

                return result.replacingImage(inflatedImage)
			}
			.start(on: QueueScheduler())
	}
}

public enum ImageInflaterRendererContentMode {
    case aspectFill
    case aspectFit
    
    // For backwards compatibility
    public static let defaultMode: ImageInflaterRendererContentMode = .aspectFill
    
    fileprivate func drawingRectForRendering(imageSize: CGSize, inSize canvasSize: CGSize) -> CGRect {
        switch self {
        case .aspectFill:
            return InflaterSizeCalculator.drawingRectForRenderingWithAspectFill(imageSize: imageSize,
                                                                                inSize: canvasSize)
        case .aspectFit:
            return InflaterSizeCalculator.drawingRectForRenderingWithAspectFit(imageSize: imageSize,
                                                                               inSize: canvasSize)
        }
    }
}

extension UIImage {
    internal func inflate(
        withSize size: CGSize,
        scale: CGFloat,
        opaque: Bool,
        contentMode: ImageInflaterRendererContentMode
    ) -> UIImage {
		return self.processImageWithBitmapContext(
			withSize: size,
			scale: scale,
			opaque: opaque,
			contentMode: contentMode,
			renderingBlock: { _, _, _, imageDrawing in
				imageDrawing()
			}
		)
	}

	internal func processImageWithBitmapContext(
		withSize size: CGSize,
		scale: CGFloat,
		opaque: Bool,
		contentMode: ImageInflaterRendererContentMode,
		renderingBlock: (_ image: UIImage, _ context: CGContext, _ contextSize: CGSize, _ imageDrawing: () -> ()) -> ())
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
			self,
			bitmapContext,
			contextSize,
			{
				let outputFrame = contentMode.drawingRectForRendering(
					imageSize: self.size * self.scale,
					inSize: contextSize
				)

				guard let imageRef = self.cgImage else { fatalError("Unable to get a CGImage from \(self).") }
				bitmapContext.draw(imageRef, in: outputFrame)
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
	public func inflatedWithScale(
        _ screenScale: CGFloat,
        opaque: Bool,
        contentMode: ImageInflaterRendererContentMode = .defaultMode
    ) -> ImageInflaterRenderer<Self.Data, Self.RenderResult, Self.Error>
    where Self.RenderResult: ImageReplacingRenderResultType
    {
		return ImageInflaterRenderer(renderer: self,
                                     screenScale: screenScale,
                                     opaque: opaque,
                                     contentMode: contentMode)
	}
}

public struct InflaterSizeCalculator {
	public static func drawingRectForRenderingWithAspectFill(imageSize: CGSize, inSize canvasSize: CGSize) -> CGRect {
		if (imageSize == canvasSize ||
			abs(imageSize.aspectRatio - canvasSize.aspectRatio) < CGFloat.ulpOfOne) {
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
    
    // TODO: write tests for this
    public static func drawingRectForRenderingWithAspectFit(imageSize: CGSize, inSize canvasSize: CGSize) -> CGRect {
        if (imageSize == canvasSize ||
            abs(imageSize.aspectRatio - canvasSize.aspectRatio) < CGFloat.ulpOfOne) {
            return CGRect(origin: .zero, size: canvasSize)
        } else {
            let destScale = min(
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
