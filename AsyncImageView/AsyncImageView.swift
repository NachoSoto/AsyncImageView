//
//  AsyncImageView.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 9/17/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift
import Result

public protocol ImageViewDataType {
	associatedtype RenderData: RenderDataType

	func renderDataWithSize(_ size: CGSize) -> RenderData
}

/// A `UIImageView` that can render asynchronously.
open class AsyncImageView<
    Data: RenderDataType,
	ImageViewData: ImageViewDataType,
	Renderer: RendererType,
	PlaceholderRenderer: RendererType>: UIImageView
	where
	ImageViewData.RenderData == Data,
	Renderer.Data == Data,
	Renderer.Error == NoError,
	PlaceholderRenderer.Data == Data,
	PlaceholderRenderer.Error == NoError,
	Renderer.RenderResult == PlaceholderRenderer.RenderResult
 {
	public enum Display {
		case empty
		case placeholder
		case data(ImageViewData)
		
		fileprivate func renderDataWithSize(_ size: CGSize) -> DataDisplay {
			switch self {
			case .empty:
				return .empty
			case .placeholder:
				return .placeholder
			case let .data(data):
				return .data(data.renderDataWithSize(size))
			}
		}
	}
	
	fileprivate enum DataDisplay: Equatable {
		case empty
		case placeholder
		case data(Data)
		
		static func == (lhs: DataDisplay, rhs: DataDisplay) -> Bool {
			switch (lhs, rhs) {
			case (.empty, .empty):
				return true
			case (.placeholder, .placeholder):
				return true
			case let (.data(lhs), .data(rhs)):
				return lhs == rhs
				
			default:
				return false
			}
		}
	}
	
	private let requestsSignal: Signal<DataDisplay, NoError>
	private let requestsObserver: Signal<DataDisplay, NoError>.Observer

	private let imageCreationScheduler: Scheduler

	public init(
		initialFrame: CGRect,
		renderer: Renderer,
		placeholderRenderer: PlaceholderRenderer? = nil,
		uiScheduler: Scheduler = UIScheduler(),
		imageCreationScheduler: Scheduler = QueueScheduler())
	{
		(self.requestsSignal, self.requestsObserver) = Signal.pipe()
		self.imageCreationScheduler = imageCreationScheduler

		super.init(frame: initialFrame)

		self.backgroundColor = nil

		self.requestsSignal
			.skipRepeats(==)
			.observe(on: uiScheduler)
			.on(value: { [weak self] in
				if
					let strongSelf = self,
					placeholderRenderer == nil || $0 == .empty {
						strongSelf.resetImage()
				}
			})
			.observe(on: self.imageCreationScheduler)
			.flatMap(.latest) { data -> SignalProducer<Renderer.RenderResult, NoError> in
				if let data = data {
					if let placeholderRenderer = placeholderRenderer {
						return placeholderRenderer
							.renderImageWithData(data)
							.take(untilReplacement: renderer.renderImageWithData(data))
					} else {
						return renderer.renderImageWithData(data)
					}
				} else {
					return .empty
				}
			}
			.observe(on: uiScheduler)
			.observeValues { [weak self] in self?.updateImage($0) }
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	open override var frame: CGRect {
		didSet {
			self.requestNewImageIfReady()
		}
	}

	open override var bounds: CGRect {
		didSet {
			self.requestNewImageIfReady()
		}
	}

	public final var data: Display {
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
		if self.bounds.size.width > 0 && self.bounds.size.height > 0 {
			self.requestNewImage(self.bounds.size, data: self.data)
		}
	}

	private func requestNewImage(_ size: CGSize, data: Display) {
		self.imageCreationScheduler.schedule { [weak instance = self, observer = self.requestsObserver] in
			if instance != nil {
				observer.send(value: data.renderDataWithSize(size))
			}
		}
	}

	// MARK: -

	private func updateImage(_ result: Renderer.RenderResult) {
		if result.cacheHit {
			self.image = result.image
		} else {
			UIView.transition(
				with: self,
				duration: fadeAnimationDuration,
				options: [.curveEaseOut, .transitionCrossDissolve],
				animations: { self.image = result.image },
				completion: nil
			)
		}
	}
}

// MARK: - Constants

private let fadeAnimationDuration: TimeInterval = 0.4
