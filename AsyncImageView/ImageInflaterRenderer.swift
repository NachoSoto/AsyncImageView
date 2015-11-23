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
public final class ImageInflaterRenderer<T: RenderDataType, E: ErrorType>: RendererType {
	private let screenScale: CGFloat
	private let renderBlock: (T) -> SignalProducer<UIImage, E>

	public init<R: RendererType where R.RenderData == T, R.Error == E>(renderer: R, screenScale: CGFloat) {
		self.screenScale = screenScale
		self.renderBlock = renderer.renderImageWithData
	}

	public func renderImageWithData(data: T) -> SignalProducer<UIImage, E> {
		return renderBlock(data)
			.map { [scale = self.screenScale] image in
				return image.inflate(withSize: data.size, scale: scale)
			}
			.startOn(QueueScheduler())
	}
}

extension UIImage {
	private func inflate(withSize size: CGSize, scale: CGFloat) -> UIImage {
		let renderSize = CGSize(
			width: size.width * scale,
			height: size.height * scale
		)

		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGImageAlphaInfo.PremultipliedLast.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue

		let imageWidth = Int(renderSize.width)
		let imageHeight = Int(renderSize.height)

		let bitmapContext = CGBitmapContextCreate(nil, imageWidth, imageHeight, 8, imageWidth * 4, colorSpace, bitmapInfo)

		guard let imageRef = self.CGImage else { fatalError("Unable to get a CGImage from \(self).") }
		CGContextDrawImage(bitmapContext, CGRect(origin: CGPointZero, size: renderSize), imageRef)

		return UIImage(CGImage: CGBitmapContextCreateImage(bitmapContext)!)
	}
}
