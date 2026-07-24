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
public final class ImageInflaterRenderer<Renderer: RendererType>: RendererType {
    public typealias ContentMode = ImageInflaterRendererContentMode
    public typealias Data = Renderer.Data
    public typealias Error = Renderer.Error
    public typealias RenderResult = ImageResult

    private let renderer: Renderer
    private let screenScale: CGFloat
	private let opaque: Bool
    private let contentMode: ContentMode
	private let bitmapContextFactory: UIImage.BitmapContextFactory

    public convenience init(
        renderer: Renderer,
        screenScale: CGFloat,
        opaque: Bool,
        contentMode: ContentMode = .defaultMode
    ) {
		self.init(
			renderer: renderer,
			screenScale: screenScale,
			opaque: opaque,
			contentMode: contentMode,
			bitmapContextFactory: UIImage.makeBitmapContext
		)
	}

	internal init(
		renderer: Renderer,
		screenScale: CGFloat,
		opaque: Bool,
		contentMode: ContentMode = .defaultMode,
		bitmapContextFactory: @escaping UIImage.BitmapContextFactory
	) {
        self.renderer = renderer
		self.screenScale = screenScale
		self.opaque = opaque
        self.contentMode = contentMode
		self.bitmapContextFactory = bitmapContextFactory
	}

	public func renderImageWithData(_ data: Data) -> SignalProducer<ImageResult, Error> {
		return self.renderer.renderImageWithData(data)
			.map { [screenScale = self.screenScale, opaque = self.opaque, contentMode = self.contentMode, bitmapContextFactory = self.bitmapContextFactory] result in
				let inflationResult = result.image.inflate(
                    withSize: data.size,
                    scale: screenScale,
                    opaque: opaque,
					contentMode: contentMode,
					bitmapContextFactory: bitmapContextFactory
                )

				return ImageResult(
					image: inflationResult.image,
					cacheHit: result.cacheHit,
					shouldCache: result.shouldCache && inflationResult.didProcess
				)
			}
			.start(on: QueueScheduler())
	}
}

public enum ImageInflaterRendererContentMode: Sendable {
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
	internal typealias BitmapContextFactory = (
		_ width: Int,
		_ height: Int,
		_ bytesPerRow: Int,
		_ colorSpace: CGColorSpace,
		_ bitmapInfo: UInt32
	) -> CGContext?
	internal typealias BitmapImageFactory = (_ context: CGContext) -> CGImage?

	internal static func makeBitmapContext(
		width: Int,
		height: Int,
		bytesPerRow: Int,
		colorSpace: CGColorSpace,
		bitmapInfo: UInt32
	) -> CGContext? {
		return CGContext(
			data: nil,
			width: width,
			height: height,
			bitsPerComponent: 8,
			bytesPerRow: bytesPerRow,
			space: colorSpace,
			bitmapInfo: bitmapInfo
		)
	}

	internal static func makeBitmapImage(_ context: CGContext) -> CGImage? {
		return context.makeImage()
	}

	internal func inflate(
		withSize size: CGSize,
		scale: CGFloat,
		opaque: Bool,
		contentMode: ImageInflaterRendererContentMode,
		bitmapContextFactory: BitmapContextFactory = UIImage.makeBitmapContext
	) -> BitmapContextProcessingResult {
		return self.processImageWithBitmapContext(
			withSize: size,
			scale: scale,
			opaque: opaque,
			contentMode: contentMode,
			bitmapContextFactory: bitmapContextFactory,
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
		bitmapContextFactory: BitmapContextFactory = UIImage.makeBitmapContext,
		bitmapImageFactory: BitmapImageFactory = UIImage.makeBitmapImage,
		renderingBlock: (_ image: UIImage, _ context: CGContext, _ contextSize: CGSize, _ imageDrawing: () -> Void) -> Void)
		-> BitmapContextProcessingResult {
		precondition(size.width > 0 && size.height > 0, "Invalid size: \(size.width)x\(size.height)")

		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let alphaInfo: CGImageAlphaInfo = (opaque) ? .noneSkipLast : .premultipliedLast
		let bitmapInfo = alphaInfo.rawValue | CGBitmapInfo.byteOrder32Little.rawValue

		let contextSize = size * scale

		let imageWidth = Int(contextSize.width)
		let imageHeight = Int(contextSize.height)

		guard let bitmapContext = bitmapContextFactory(
			imageWidth,
			imageHeight,
			imageWidth * 4,
			colorSpace,
			bitmapInfo
		) else {
			return BitmapContextProcessingResult(image: self, didProcess: false)
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

		guard let processedImage = bitmapImageFactory(bitmapContext) else {
			return BitmapContextProcessingResult(image: self, didProcess: false)
		}

		return BitmapContextProcessingResult(
			image: UIImage(
				cgImage: processedImage,
				scale: scale,
				orientation: self.imageOrientation
			),
			didProcess: true
		)
	}
}

internal struct BitmapContextProcessingResult {
	let image: UIImage
	let didProcess: Bool
}

extension RendererType {
	public func inflatedWithScale(
        _ screenScale: CGFloat,
        opaque: Bool,
        contentMode: ImageInflaterRendererContentMode = .defaultMode
    ) -> ImageInflaterRenderer<Self> {
		return ImageInflaterRenderer(renderer: self,
                                     screenScale: screenScale,
                                     opaque: opaque,
                                     contentMode: contentMode)
	}
}

public struct InflaterSizeCalculator {
	public static func drawingRectForRenderingWithAspectFill(imageSize: CGSize, inSize canvasSize: CGSize) -> CGRect {
		if imageSize == canvasSize ||
			abs(imageSize.aspectRatio - canvasSize.aspectRatio) < CGFloat.ulpOfOne {
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
        if imageSize == canvasSize ||
            abs(imageSize.aspectRatio - canvasSize.aspectRatio) < CGFloat.ulpOfOne {
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

private func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
	return CGSize(
		width: lhs.width * rhs,
		height: lhs.height * rhs
	)
}
