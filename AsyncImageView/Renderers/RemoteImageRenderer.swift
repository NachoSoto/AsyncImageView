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

public protocol RemoteRenderDataType: RenderDataType {
	var imageURL: NSURL { get }
}

/// `RendererType` which downloads images.
///
/// Note that this Renderer will ignore `RenderDataType.size` and instead
/// download the original image.
/// Consider chaining this with `ImageInflaterRenderer`.
public final class RemoteImageRenderer<T: RemoteRenderDataType>: RendererType {
	private let session: NSURLSession

	public init(session: NSURLSession = NSURLSession.sharedSession()) {
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
	}
}

public enum RemoteImageRendererError: ErrorType {
	case LoadingError(originalError: NSError)
	case DecodingError
}
