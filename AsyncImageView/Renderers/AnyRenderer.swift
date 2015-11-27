//
//  AnyRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa

/// A type-erased `RendererType`.
public final class AnyRenderer<
	Data: RenderDataType, Result: RenderResultType, Error: ErrorType
>: RendererType {
	private let renderBlock: (Data) -> SignalProducer<Result, Error>

	/// Creates an `AnyRenderer` based on another `RendererType`.
	public convenience init<
		R: RendererType
		where R.Data == Data, R.Result == Result, R.Error == Error
		>(_ renderer: R)
	{
		self.init(renderBlock: renderer.renderImageWithData)
	}

	private init(renderBlock: (Data) -> SignalProducer<Result, Error>) {
		self.renderBlock = renderBlock
	}

	public func renderImageWithData(data: Data) -> SignalProducer<Result, Error> {
		return self.renderBlock(data)
	}
}

extension SynchronousRendererType {
	/// Constructs an `AnyRenderer` with a `SynchronousRendererType`.
	/// The created `SignalProducer` will simply emit the result
	/// of `renderImageWithData`.
	public var asyncRenderer: AnyRenderer<Self.Data, UIImage, NoError> {
		return AnyRenderer { data in
			return SignalProducer { observer, disposable in
				if !disposable.disposed {
					observer.sendNext(self.renderImageWithData(data))
					observer.sendCompleted()
				} else {
					observer.sendInterrupted()
				}
			}
				.startOn(QueueScheduler())
		}
	}
}
