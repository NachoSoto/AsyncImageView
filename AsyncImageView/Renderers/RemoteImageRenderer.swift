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
	var imageURL: URL { get }
}

/// `RendererType` which downloads images.
///
/// Note that this Renderer will ignore `RenderDataType.size` and instead
/// download the original image.
/// Consider chaining this with `ImageInflaterRenderer`.
public final class RemoteImageRenderer<T: RemoteRenderDataType>: RendererType {
	private let session: URLSession

	public init(session: URLSession = URLSession.shared) {
		self.session = session
	}

	public func renderImageWithData(_ data: T) -> SignalProducer<UIImage, RemoteImageRendererError> {
		return self.session.rac_dataWithRequest(URLRequest(url: data.imageURL))
			.mapError(RemoteImageRendererError.loadingError)
			.attemptMap { (data, response) in
				Result(
					(response as? HTTPURLResponse).map { (data, $0) },
					failWith: .invalidResponse
				)
			}
			.flatMap(.merge) { (data, response) -> SignalProducer<Foundation.Data, RemoteImageRendererError> in
				let statusCode = response.statusCode

				if statusCode >= 200 && statusCode < 300 {
					return SignalProducer(value: data)
				} else {
					return SignalProducer(error: .invalidStatusCode(statusCode: statusCode))
				}
			}
			.observe(on: QueueScheduler())
			.flatMap(.merge) { data in
				return SignalProducer
					.attempt {
						return Result(
							UIImage(data: data),
							failWith: RemoteImageRendererError.decodingError
						)
				}
		}
	}
}

public enum RemoteImageRendererError: ErrorProtocol {
	case loadingError(originalError: NSError)
	case invalidResponse
	case invalidStatusCode(statusCode: Int)
	case decodingError
}
