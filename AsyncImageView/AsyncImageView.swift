//
//  AsyncImageView.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 9/17/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import Combine

@preconcurrency import ReactiveSwift

public protocol ImageViewDataType {
	associatedtype RenderData: RenderDataType

	func renderDataWithSize(_ size: CGSize) -> RenderData
}

#if !os(watchOS)

/// A `UIImageView` that can render asynchronously.
open class AsyncImageView<
	Data: RenderDataType,
	ImageViewData: ImageViewDataType,
	Renderer: RendererType,
	PlaceholderRenderer: RendererType>: UIImageView
	where
		ImageViewData.RenderData == Data,
		Renderer.Data == Data,
		Renderer.Error == Never,
		PlaceholderRenderer.Data == Data,
		PlaceholderRenderer.Error == Never,
		Renderer.RenderResult == PlaceholderRenderer.RenderResult {
	private typealias ImageLoader = AsyncImageLoader<Data, ImageViewData, Renderer, PlaceholderRenderer>

	private let requestsSignal: Signal<ImageLoader.Request, Never>
	private let requestsObserver: Signal<ImageLoader.Request, Never>.Observer

	private let imageCreationScheduler: ReactiveSwift.Scheduler

	private var disposable: Disposable?

	public init(
		initialFrame: CGRect,
		renderer: Renderer,
		placeholderRenderer: PlaceholderRenderer? = nil,
		uiScheduler: ReactiveSwift.Scheduler = UIScheduler(),
		imageCreationScheduler: ReactiveSwift.Scheduler = QueueScheduler()
	) {
		(self.requestsSignal, self.requestsObserver) = Signal.pipe()
		self.imageCreationScheduler = imageCreationScheduler

		super.init(frame: initialFrame)

		self.backgroundColor = nil

		self.disposable = ImageLoader.createSignal(
			requestsSignal: self.requestsSignal,
			renderer: renderer,
			placeholderRenderer: placeholderRenderer,
			uiScheduler: uiScheduler
		)
		.observeValues { [weak self] result in
			self?.updateImage(result)
		}
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		self.disposable?.dispose()
	}

	open override var frame: CGRect {
		didSet {
			if self.frame.size != oldValue.size {
				self.requestNewImageIfReady()
			}
		}
	}

	open override var bounds: CGRect {
		didSet {
			if self.bounds.size != oldValue.size {
				self.requestNewImageIfReady()
			}
		}
	}

	/// Assigning data uses the default transition and placeholder behavior.
	public final var data: ImageViewData? {
		get { self.viewData }
		set { self.setData(newValue) }
	}

	/// Update the image with presentation options captured by this request.
	/// Identical render data is still deduplicated, regardless of presentation options.
	/// Updates wait until the view has a window and nonzero size.
	/// Passing nil clears the image and cancels the previous request.
	public final func setData(
		_ data: ImageViewData?,
		transition: ImageTransition = .automatic,
		placeholderPolicy: ImagePlaceholderPolicy = .standard
	) {
		self.viewData = data
		self.transition = transition
		self.placeholderPolicy = placeholderPolicy
		self.requestNewImageIfReady()
	}

	private var viewData: ImageViewData?
	private var transition: ImageTransition = .automatic
	private var placeholderPolicy: ImagePlaceholderPolicy = .standard

	open override func didMoveToWindow() {
		super.didMoveToWindow()

		if self.window != nil {
			self.requestNewImageIfReady()
		}
	}

	// MARK: -

	private func requestNewImageIfReady() {
		if self.window != nil && self.bounds.size.width > 0 && self.bounds.size.height > 0 {
			self.requestNewImage(self.bounds.size, data: self.data)
		}
	}

	private func requestNewImage(_ size: CGSize, data: ImageViewData?) {
		let transition = self.transition
		let placeholderPolicy: ImagePlaceholderPolicy = self.placeholderPolicy == .keepCurrentImage && self.image == nil
			? .standard
			: self.placeholderPolicy
		self.imageCreationScheduler.schedule { [weak self, observer = self.requestsObserver] in
			if self != nil {
				observer.send(value: ImageLoader.Request(
					data: data?.renderDataWithSize(size),
					transition: transition,
					placeholderPolicy: placeholderPolicy
				))
			}
		}
	}

	// MARK: -

	private func updateImage(_ update: ImageLoader.Update) {
		if let result = update.result {
			if let duration = update.transition.duration(cacheHit: result.cacheHit), duration > 0 {
				UIView.transition(
					with: self,
					duration: duration,
					options: [.curveEaseOut, .transitionCrossDissolve],
					animations: { self.image = result.image },
					completion: nil
				)
			} else {
				self.image = result.image
			}
		} else {
			self.image = nil
		}
	}
}

#endif

// MARK: - Constants

internal let fadeAnimationDuration: TimeInterval = 0.3
