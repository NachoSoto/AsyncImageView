//
//  RemoteImageRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift
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
		return self.session.reactive.data(with: URLRequest(url: data.imageURL))
            .mapError(RemoteImageRendererError.loadingError)
            .attemptMap { data in
                return Result(
                    (data.1 as? HTTPURLResponse).map { (data.0, $0) },
                    failWith: .invalidResponse
                )
            }
            .flatMap(.merge) { data -> SignalProducer<Foundation.Data, RemoteImageRendererError> in
                let statusCode = data.1.statusCode

                if statusCode >= 200 && statusCode < 300 {
                    return SignalProducer(value: data.0)
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

public enum RemoteImageRendererError: Error {
	case loadingError(AnyError)
	case invalidResponse
	case invalidStatusCode(statusCode: Int)
	case decodingError
}
