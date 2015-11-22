//
//  AsyncImageView.swift
//  ChessWatchApp
//
//  Created by Nacho Soto on 9/17/15.
//  Copyright © 2015 Javier Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa

public protocol ImageViewDataType {
	typealias ValueType
	typealias RenderData: RenderDataType

	var data: ValueType { get }

	func renderDataWithSize(size: CGSize) -> RenderData
}

private let imageProducerCreationScheduler = QueueScheduler()

private let scheduler = UIScheduler()

/// A UIImageView that can render asynchronously.
public final class AsyncImageView<
	RenderData: RenderDataType,
	ImageViewData: ImageViewDataType,
	ImageProvider: ImageProviderType
	where
	ImageViewData.RenderData == RenderData,
	ImageProvider.RenderData == RenderData
>: UIImageView {
	private let requestsSignal: Signal<RenderData, NoError>
	private let requestsObserver: Signal<RenderData, NoError>.Observer

	public init(initialFrame: CGRect, imageProvider: ImageProvider) {
		(self.requestsSignal, self.requestsObserver) = Signal.pipe()

		super.init(frame: initialFrame)

		self.backgroundColor = nil

		let requestChanges = self.requestsSignal.skipRepeats()

		requestChanges
			.observeOn(scheduler)
			.observeNext { [weak self] _ in self?.resetImage() }

		requestChanges
			.observeOn(imageProducerCreationScheduler)
			.flatMap(.Latest, transform: imageProvider.getImageForData)
			.observeOn(scheduler)
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
			if let data = data {
				requestNewImage(frame.size, data: data)
			}
		}
	}

	public var data: ImageViewData! // TODO: request image too!

	private func resetImage() {
		// Avoid displaying some stale image
		self.image = nil
	}

	private func requestNewImage(size: CGSize, data: ImageViewData) {
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { [weak instance = self, observer = self.requestsObserver] in
			if instance != nil {
				observer.sendNext(data.renderDataWithSize(size))
			}
		}
	}

	// MARK: -

	private func updateImage(result: RenderResult) {
		if result.cacheHit {
			self.image = result.image
		} else {
			UIView.transitionWithView(
				self,
				duration: 0.4,
				options: [.CurveEaseOut, .TransitionCrossDissolve],
				animations: { self.image = result.image },
				completion: nil
			)
		}
	}
}
