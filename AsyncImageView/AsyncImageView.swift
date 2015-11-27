//
//  AsyncImageView.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 9/17/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa

public protocol ImageViewDataType {
	typealias ValueType
	typealias RenderData: RenderDataType

	var data: ValueType { get }

	func renderDataWithSize(size: CGSize) -> RenderData
}

/// A UIImageView that can render asynchronously.
public final class AsyncImageView<
	RenderData: RenderDataType,
	ImageViewData: ImageViewDataType,
	Renderer: RendererType
	where
	ImageViewData.RenderData == RenderData,
	Renderer.RenderData == RenderData,
	Renderer.Error == NoError
>: UIImageView {
	private let requestsSignal: Signal<RenderData, NoError>
	private let requestsObserver: Signal<RenderData, NoError>.Observer

	private let imageCreationScheduler: SchedulerType

	public init(
		initialFrame: CGRect,
		renderer: Renderer,
		imageCreationScheduler: SchedulerType = QueueScheduler())
	{
		(self.requestsSignal, self.requestsObserver) = Signal.pipe()
		self.imageCreationScheduler = imageCreationScheduler

		super.init(frame: initialFrame)

		self.backgroundColor = nil

		let uiScheduler = UIScheduler()

		self.requestsSignal
			.skipRepeats()
			.observeOn(uiScheduler)
			.on(next: { [weak self] _ in self?.resetImage() })
			.observeOn(self.imageCreationScheduler)
			.flatMap(.Latest, transform: renderer.renderImageWithData)
			.observeOn(uiScheduler)
			.observeNext { [weak self] in self?.updateImage($0) }
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		requestsObserver.sendCompleted()
	}

	public override var frame: CGRect {
		didSet {
			self.requestNewImageIfReady()
		}
	}

	public var data: ImageViewData! {
		didSet {
			self.requestNewImageIfReady()
		}
	}

	// MARK: -

	private func resetImage() {
		// Avoid displaying a stale image.
		self.image = nil
	}

	private func requestNewImageIfReady() {
		if let data = data, size = Optional(self.frame.size)
			where size.width > 0 && size.height > 0 {
				self.requestNewImage(size, data: data)
		}
	}

	private func requestNewImage(size: CGSize, data: ImageViewData) {
		self.imageCreationScheduler.schedule { [weak instance = self, observer = self.requestsObserver] in
			if instance != nil {
				observer.sendNext(data.renderDataWithSize(size))
			}
		}
	}

	// MARK: -

	private func updateImage(result: Renderer.Result) {
		if result.cacheHit {
			self.image = result.image
		} else {
			UIView.transitionWithView(
				self,
				duration: fadeAnimationDuration,
				options: [.CurveEaseOut, .TransitionCrossDissolve],
				animations: { self.image = result.image },
				completion: nil
			)
		}
	}
}

// MARK: - Constants

private let fadeAnimationDuration: NSTimeInterval = 0.4

private extension SignalType {
	// TODO: remove once https://github.com/ReactiveCocoa/ReactiveCocoa/pull/2572 is merged.
	func on(next next: (Value) -> ()) -> Signal<Value, Error> {
		return self.map {
			next($0)
			return $0
		}
	}
}
