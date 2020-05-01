//
//  AsyncImageView.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 9/17/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import Combine

import ReactiveSwift

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
	Renderer.Error == Never,
	PlaceholderRenderer.Data == Data,
	PlaceholderRenderer.Error == Never,
	Renderer.RenderResult == PlaceholderRenderer.RenderResult
 {
	private let requestsSignal: Signal<Data?, Never>
	private let requestsObserver: Signal<Data?, Never>.Observer

    private let imageCreationScheduler: ReactiveSwift.Scheduler

    private let loader: AsyncImageLoader<Data, ImageViewData, Renderer, PlaceholderRenderer>
    private var observation: AnyCancellable?
    
	public init(
		initialFrame: CGRect,
		renderer: Renderer,
		placeholderRenderer: PlaceholderRenderer? = nil,
        uiScheduler: ReactiveSwift.Scheduler = UIScheduler(),
        imageCreationScheduler: ReactiveSwift.Scheduler = QueueScheduler())
	{
		(self.requestsSignal, self.requestsObserver) = Signal.pipe()
		self.imageCreationScheduler = imageCreationScheduler

        self.loader = AsyncImageLoader(
            requestsSignal: self.requestsSignal,
            renderer: renderer,
            placeholderRenderer: placeholderRenderer,
            uiScheduler: uiScheduler,
            imageCreationScheduler: imageCreationScheduler
        )
        
		super.init(frame: initialFrame)

		self.backgroundColor = nil
        
        self.observation = self.loader.$renderResult.sink { [weak self] result in
            self?.updateImage(result)
        }
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

	public final var data: ImageViewData? {
		didSet {
			self.requestNewImageIfReady()
		}
	}

	// MARK: -

	private func requestNewImageIfReady() {
		if self.bounds.size.width > 0 && self.bounds.size.height > 0 {
			self.requestNewImage(self.bounds.size, data: self.data)
		}
	}

	private func requestNewImage(_ size: CGSize, data: ImageViewData?) {
		self.imageCreationScheduler.schedule { [weak self, observer = self.requestsObserver] in
			if self != nil {
				observer.send(value: data?.renderDataWithSize(size))
			}
		}
	}

	// MARK: -

	private func updateImage(_ result: Renderer.RenderResult?) {
        if let result = result {
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
        else {
            self.image = nil
        }
	}
}

// MARK: - Constants

internal let fadeAnimationDuration: TimeInterval = 0.4
