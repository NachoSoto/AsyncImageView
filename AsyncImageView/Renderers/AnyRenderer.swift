//
//  AnyRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift

/// A type-erased `RendererType`.
public final class AnyRenderer<
	Data: RenderDataType,
	RenderResult: RenderResultType,
	Error: Swift.Error
>: RendererType {
	private let renderBlock: (Data) -> SignalProducer<RenderResult, Error>

	/// Creates an `AnyRenderer` based on another `RendererType`.
	public convenience init<R: RendererType>(_ renderer: R)
		where R.Data == Data, R.RenderResult == RenderResult, R.Error == Error
	{
		self.init(renderBlock: renderer.renderImageWithData)
	}

	fileprivate init(renderBlock: @escaping (Data) -> SignalProducer<RenderResult, Error>) {
		self.renderBlock = renderBlock
	}

	public func renderImageWithData(_ data: Data) -> SignalProducer<RenderResult, Error> {
		return self.renderBlock(data)
	}
}

extension SynchronousRendererType {
	/// Constructs an `AnyRenderer` with a `SynchronousRendererType`.
	/// The created `SignalProducer` will simply emit the result
	/// of `renderImageWithData`.
	public func asyncRenderer(_ scheduler: Scheduler = QueueScheduler()) -> AnyRenderer<Self.Data, UIImage, Never> {
		return AnyRenderer { (data: Self.Data) in
			return SignalProducer { observer, lifetime in
				if !lifetime.hasEnded {
					observer.send(value: self.renderImageWithData(data))
					observer.sendCompleted()
				} else {
					observer.sendInterrupted()
				}
			}
				.start(on: scheduler)
		}
	}
}

extension RendererType {
	/// Creates a new `RendererType` that maps the data necessary
	/// to produce images, by applying the given block.
	///
	/// This is useful when you want to compose two renderers 
	/// with different `RenderDataType`s.
	public func mapData<NewData: RenderDataType>(_ mapper: @escaping (NewData) -> Self.Data)
		-> AnyRenderer<NewData, Self.RenderResult, Self.Error> {
			return AnyRenderer { data in
				return self.renderImageWithData(mapper(data))
			}
	}
}
