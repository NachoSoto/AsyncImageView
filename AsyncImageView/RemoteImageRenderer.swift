//
//  RemoteImageRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import Foundation
import UIKit

import ReactiveCocoa

public protocol RemoteImageData: RenderDataType {
	var imageURL: NSURL { get }
}

/// `RendererType` which downloads images.
public final class RemoteImageRenderer<T: RemoteImageData>: RendererType {
	private let screenScale: CGFloat
	private let session: NSURLSession

	public init(screenScale: CGFloat, session: NSURLSession = NSURLSession.sharedSession()) {
		self.screenScale = screenScale
		self.session = session
	}

	public func renderImageWithData(data: T) -> SignalProducer<UIImage, RemoteImageRendererError> {
		return self.session.rac_dataWithRequest(NSURLRequest(URL: data.imageURL))
			.mapError(RemoteImageRendererError.LoadingError)
			.observeOn(QueueScheduler())
			.flatMap(.Merge) { (data, response) -> SignalProducer<UIImage, RemoteImageRendererError> in
				if let image = UIImage(data: data) {
					return SignalProducer(value: image)
				} else {
					return SignalProducer(error: .DecodingError)
				}
			}
			.map { [scale = self.screenScale] image in
				return image.inflate(withSize: data.size, scale: scale)
			}
	}
}

public enum RemoteImageRendererError: ErrorType {
	case LoadingError(originalError: NSError)
	case DecodingError
}
