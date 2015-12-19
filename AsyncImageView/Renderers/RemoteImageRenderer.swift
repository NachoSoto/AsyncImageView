//
//  RemoteImageRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveCocoa
import Result

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
			.attemptMap { (data, response) in
				Result(
					(response as? NSHTTPURLResponse).map { (data, $0) },
					failWith: .InvalidResponse
				)
			}
			.flatMap(.Merge) { (data, response) -> SignalProducer<NSData, RemoteImageRendererError> in
				let statusCode = response.statusCode

				if statusCode >= 200 && statusCode < 300 {
					return SignalProducer(value: data)
				} else {
					return SignalProducer(error: .InvalidStatusCode(statusCode: statusCode))
				}
			}
			.observeOn(QueueScheduler())
			.flatMap(.Merge) { data in
				return SignalProducer
					.attempt {
						return Result(
							UIImage(data: data),
							failWith: RemoteImageRendererError.DecodingError
						)
				}
		}
	}
}

public enum RemoteImageRendererError: ErrorType {
	case LoadingError(originalError: NSError)
	case InvalidResponse
	case InvalidStatusCode(statusCode: Int)
	case DecodingError
}
