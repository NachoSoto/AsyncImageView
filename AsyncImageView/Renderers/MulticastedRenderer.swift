//
//  MulticastedRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift

private final class InFlightImage {
	let result: Property<ImageResult?>
	let observer: Signal<ImageResult, Never>.Observer
	let disposable = SerialDisposable()
	private let hasStarted = Atomic(false)

	init() {
		let (signal, observer) = Signal<ImageResult, Never>.pipe()
		self.result = Property(initial: nil, then: signal)
		self.observer = observer
	}

	deinit {
		self.disposable.dispose()
	}

	func startIfNeeded(_ action: () -> Void) {
		let shouldStart = self.hasStarted.modify { hasStarted in
			guard !hasStarted else { return false }
			hasStarted = true

			return true
		}

		if shouldStart {
			action()
		}
	}
}

private enum CachedImage {
	case rendering(InFlightImage, latest: ImageResult?)
	case completed(ImageResult)
}

private enum CachedImageLookup {
	case rendering(InFlightImage)
	case completed(ImageResult)
}

/// `RendererType` decorator which guarantees that images for a given `RenderDataType`
/// are only rendered once, and multicasted to every observer.
public final class MulticastedRenderer<
	Renderer: RendererType,
    Data: RenderDataType
>: RendererType
	where
	Renderer.Data == Data,
	Renderer.Error == Never {
	private let renderer: Renderer
	private let cache: Atomic<[Data: CachedImage]>

    #if !os(watchOS)
	private let memoryWarningDisposable: Disposable
    #endif

	public init(renderer: Renderer) {
		self.renderer = renderer
		self.cache = Atomic([:])

        #if !os(watchOS)
		self.memoryWarningDisposable = MulticastedRenderer.clearCacheOnMemoryWarning(self.cache)
        #endif
	}

	deinit {
        #if !os(watchOS)
		self.memoryWarningDisposable.dispose()
        #endif
	}

	public func renderImageWithData(_ data: Data) -> SignalProducer<ImageResult, Never> {
		switch self.lookup(for: data) {
		case let .completed(result):
			return SignalProducer(value: result)

		case let .rendering(entry):
			return self.producer(for: data, entry: entry)
		}
	}

	private func lookup(for data: Data) -> CachedImageLookup {
		return self.cache.modify { cache in
			switch cache[data] {
			case let .completed(result), let .rendering(_, latest: result?):
				return .completed(result)

			case let .rendering(entry, latest: nil):
				return .rendering(entry)

			case nil:
				let entry = InFlightImage()
				cache[data] = .rendering(entry, latest: nil)

				return .rendering(entry)
			}
		}
	}

	private func startRendering(_ data: Data, into entry: InFlightImage) {
		entry.disposable.inner = self.renderer
			.renderImageWithData(data)
			.start { [weak self, weak entry] event in
				guard let self, let entry else { return }

				if let result = event.value {
					self.receive(result, for: data, entry: entry)
				} else if event.isTerminating {
					self.finishRendering(data, entry: entry)
				}
			}
	}

	private func receive(_ result: Renderer.RenderResult, for data: Data, entry: InFlightImage) {
		let cacheMiss = ImageResult(
			image: result.image,
			cacheHit: false,
			shouldCache: result.shouldCache
		)

		guard result.shouldCache else {
			self.remove(entry, for: data)
			entry.observer.send(value: cacheMiss)

			return
		}

		let cacheHit = ImageResult(image: result.image, cacheHit: true, shouldCache: true)
		self.cache.modify { cache in
			guard case let .rendering(current, _) = cache[data], current === entry else { return }
			cache[data] = .rendering(entry, latest: cacheHit)
		}

		entry.observer.send(value: cacheMiss)
		entry.observer.send(value: cacheHit)
	}

	private func finishRendering(_ data: Data, entry: InFlightImage) {
		self.cache.modify { cache in
			guard case let .rendering(current, latest) = cache[data], current === entry else { return }

			cache[data] = latest.map(CachedImage.completed)
		}
		entry.observer.sendCompleted()
	}

	private func remove(_ entry: InFlightImage, for data: Data) {
		self.cache.modify { cache in
			guard case let .rendering(current, _) = cache[data], current === entry else { return }
			cache[data] = nil
		}
	}

	private func producer(for data: Data, entry: InFlightImage) -> SignalProducer<ImageResult, Never> {
		return SignalProducer { [self, entry] observer, lifetime in
			lifetime.observeEnded {
				_ = self
				_ = entry
			}

			let cachedResult = self.cache.withValue { cache -> ImageResult? in
				switch cache[data] {
				case let .completed(result), let .rendering(_, latest: result?):
					return result

				case .rendering(_, latest: nil), nil:
					return nil
				}
			}

			if let cachedResult {
				lifetime += SignalProducer(value: cachedResult).start(observer)
			} else {
				lifetime += entry.result.producer
					.compactMap { $0 }
					.take(first: 1)
					.start(observer)
				entry.startIfNeeded {
					self.startRendering(data, into: entry)
				}
			}
		}
	}

    #if !os(watchOS)
	private static func clearCacheOnMemoryWarning(_ cache: Atomic<[Data: CachedImage]>) -> Disposable {
		return NotificationCenter.default
			.reactive.notifications(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil)
			.observe(on: QueueScheduler())
			.observeValues { _ in
				cache.modify { $0 = [:] }
			}!
	}
    #endif
}

extension RendererType where Error == Never {
	/// Multicasts the results of this `RendererType`.
	public func multicasted() -> MulticastedRenderer<Self, Self.Data> {
		return MulticastedRenderer(renderer: self)
	}
}
