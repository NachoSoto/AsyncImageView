//
//  Renderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa

/// Information required to produce an image
public protocol RenderDataType: Hashable {
	var size: CGSize { get }
}

public struct RenderResult {
	let image: UIImage
	let cacheHit: Bool
}

public protocol RendererType {
	typealias RenderData: RenderDataType
	typealias Error: ErrorType

	func renderImageWithData(data: RenderData) -> SignalProducer<UIImage, Error>
}

public protocol SynchronousRendererType {
	typealias RenderData: RenderDataType

	func renderImageWithData(data: RenderData) -> UIImage
}

/// A type-erased `RendererType`.
public final class AnyRenderer<T: RenderDataType, E: ErrorType>: RendererType {
	private let renderBlock: (T) -> SignalProducer<UIImage, E>

	/// Constructs an `AnyRenderer` with a `SynchronousRendererType`.
	/// The created `SignalProducer` will simply emit the result 
	/// of `renderImageWithData`.
	public convenience init<R: SynchronousRendererType where R.RenderData == T>(renderer: R) {
		self.init { data in
			return SignalProducer { observer, disposable in
				if !disposable.disposed {
					observer.sendNext(renderer.renderImageWithData(data))
					observer.sendCompleted()
				} else {
					observer.sendInterrupted()
				}
			}
		}
	}

	/// Creates an `AnyRenderer` based on another `RendererType`.
	public convenience init<R: RendererType where R.RenderData == T, R.Error == E>(renderer: R) {
		self.init(renderBlock: renderer.renderImageWithData)
	}

	private init(renderBlock: (T) -> SignalProducer<UIImage, E>) {
		self.renderBlock = renderBlock
	}

	public func renderImageWithData(data: T) -> SignalProducer<UIImage, E> {
		return self.renderBlock(data)
	}
}

extension SynchronousRendererType {
	public var asyncRenderer: AnyRenderer<Self.RenderData, NoError> {
		return AnyRenderer(renderer: self)
	}
}
