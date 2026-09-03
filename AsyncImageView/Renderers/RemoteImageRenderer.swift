//
//  RemoteImageRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift

public protocol RemoteRenderDataType: RenderDataType {
	var imageURL: URL { get }
}

/// `RendererType` which downloads images.
///
/// Note that this Renderer will ignore `RenderDataType.size` and instead
/// download the original image.
/// Consider chaining this with `ImageInflaterRenderer`.
public final class RemoteImageRenderer<T: RemoteRenderDataType>: RendererType {
	private let renderer: RemoteImageDataRenderer<T, UIImage>

	public init(session: URLSession = URLSession.shared) {
		self.renderer = RemoteImageDataRenderer(session: session) { UIImage(data: $0) }
	}

	public func renderImageWithData(_ data: T) -> SignalProducer<UIImage, RemoteImageRendererError> {
		return self.renderer.renderImageWithData(data)
	}
}

/// `RendererType` which downloads encoded image data and decodes it into a custom render result.
public final class RemoteImageDataRenderer<T: RemoteRenderDataType, Result: RenderResultType>: RendererType {
	public typealias Decoder = (Data) -> Result?

	private let session: URLSession
	private let decoder: Decoder

	public init(
		session: URLSession = URLSession.shared,
		decoder: @escaping Decoder
	) {
		self.session = session
		self.decoder = decoder
	}

	public func renderImageWithData(_ data: T) -> SignalProducer<Result, RemoteImageRendererError> {
		return self.session.reactive.data(with: URLRequest(url: data.imageURL))
			.mapError(RemoteImageRendererError.loadingError)
			.attemptMap { (data, response) in
				Swift.Result(
					(response as? HTTPURLResponse).map { (data, $0) },
					failWith: .invalidResponse
				)
			}
			.flatMap(.merge) { (content, response) -> SignalProducer<Foundation.Data, RemoteImageRendererError> in
				let statusCode = response.statusCode

				if statusCode >= 200 && statusCode < 300 {
					return SignalProducer(value: content)
				} else if statusCode == 404 {
                    return SignalProducer(error: .notFound(url: data.imageURL))
                } else {
					return SignalProducer(error: .invalidStatusCode(statusCode: statusCode))
				}
			}
			.observe(on: QueueScheduler())
			.flatMap(.merge) { [decoder = self.decoder] data in
                return SignalProducer {
                    Swift.Result(
						decoder(data),
                        failWith: RemoteImageRendererError.decodingError
                    )
                }
		}
	}
}

public enum RemoteImageRendererError: Error {
	case loadingError(originalError: Error)
	case invalidResponse
    case notFound(url: URL)
	case invalidStatusCode(statusCode: Int)
	case decodingError
}
