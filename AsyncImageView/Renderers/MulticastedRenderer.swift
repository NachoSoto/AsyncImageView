//
//  MulticastedRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa

// The initial value is `nil`.
private typealias ImageProperty = AnyProperty<ImageResult?>

/// `RendererType` decorator which guarantees that images for a given `RenderDataType`
/// are only rendered once, and multicasted to every observer.
public final class MulticastedRenderer<
	Data: RenderDataType,
	Renderer: RendererType
	where
	Renderer.Data == Data,
	Renderer.Error == NoError
>: RendererType {
	private let renderer: Renderer
	private let cache: Atomic<[Data : ImageProperty]>

	private let memoryWarningDisposable: Disposable

	public init(renderer: Renderer) {
		self.renderer = renderer
		self.cache = Atomic([:])

		self.memoryWarningDisposable = MulticastedRenderer.clearCacheOnMemoryWarning(self.cache)
	}

	deinit {
		self.memoryWarningDisposable.dispose()
	}

	public func renderImageWithData(data: Data) -> SignalProducer<ImageResult, NoError> {
		let property = getPropertyForData(data)

		return property.producer
			.filter { $0 != nil } // Skip initial `nil` value.
			.map { $0! }
			.take(1)
 	}

	private func getPropertyForData(data: Data) -> ImageProperty {
		var result: ImageProperty!

		self.cache.modify { cache in
			var mutableCache = cache

			if let property = cache[data] {
				result = property
				return cache
			}

			result = ImageProperty(
				initialValue: nil,
				producer: renderer.createProducerForRenderingData(data)
					.map(Optional.init)
			)

			mutableCache[data] = result
			return mutableCache
		}

		return result
	}

	private static func clearCacheOnMemoryWarning(cache: Atomic<[Data : ImageProperty]>) -> Disposable {
		return NSNotificationCenter.defaultCenter()
			.rac_notifications(UIApplicationDidReceiveMemoryWarningNotification, object: nil)
			.observeOn(QueueScheduler())
			.startWithNext { _ in
				cache.modify { _ in [:] }
			}
	}
}

extension RendererType where Error == NoError {
	/// Multicasts the results of this `RendererType`.
	public func multicasted() -> MulticastedRenderer<Self.Data, Self> {
		return MulticastedRenderer(renderer: self)
	}
}

extension RendererType {
	private func createProducerForRenderingData(data: Data) -> SignalProducer<ImageResult, Error> {
		return self.renderImageWithData(data)
			.flatMap(.Concat) { result in
				return SignalProducer(values: [
					ImageResult(image: result.image, cacheHit: false),
					ImageResult(image: result.image, cacheHit: true)
				])
		}
	}
}

extension SignalProducerType {
	public func replayLazily(capacity: Int = Int.max) -> SignalProducer<Value, Error> {
//		precondition(capacity >= 0, "Invalid capacity: \(capacity)")
//
//		let state: Atomic<BufferState<Value, Error>?> = Atomic(nil)
//
//		let bufferingObserver: Signal<Value, Error>.Observer = Observer { event in
//			state.modify { state in
//				var mutableState = state!
//
//				if let value = event.value {
//					mutableState.addValue(value, upToCapacity: capacity)
//				} else {
//					mutableState.terminationEvent = event
//				}
//
//				return mutableState
//			}
//		}
//
//		return SignalProducer { observer, disposable in
//			state.modify { value in
//				if value == nil {
//					// Only start for the first subscription.
//					disposable += self.start(bufferingObserver)
//
//					return BufferState()
//				} else {
//					return value
//				}
//			}
//		}

		var producer: SignalProducer<Value, Error>?
		var producerObserver: SignalProducer<Value, Error>.ProducedSignal.Observer?

		let lock = NSLock()
		lock.name = "org.reactivecocoa.ReactiveCocoa.SignalProducer.replayLazily"

		return SignalProducer { observer, disposable in
			let initializedProducer: SignalProducer<Value, Error>
			let initializedObserver: SignalProducer<Value, Error>.ProducedSignal.Observer
			let shouldStartUnderlyingProducer: Bool

			lock.lock()
			if let producer = producer, producerObserver = producerObserver {
				(initializedProducer, initializedObserver) = (producer, producerObserver)
				shouldStartUnderlyingProducer = false
			} else {
				let (producerTemp, observerTemp) = SignalProducer<Value, Error>.buffer(capacity)

				(producer, producerObserver) = (producerTemp, observerTemp)
				(initializedProducer, initializedObserver) = (producerTemp, observerTemp)
				shouldStartUnderlyingProducer = true
			}
			lock.unlock()

			disposable += initializedProducer.start(observer)

			if shouldStartUnderlyingProducer {
				self.start(initializedObserver)
			}
		}
	}
}

// TODO: remove
private struct BufferState<Value, Error: ErrorType> {
	// All values in the buffer.
	var values: [Value] = []

	// Any terminating event sent to the buffer.
	//
	// This will be nil if termination has not occurred.
	var terminationEvent: Event<Value, Error>?

	// The observers currently attached to the buffered producer, or nil if the
	// producer was terminated.
	var observers: Bag<Signal<Value, Error>.Observer>? = Bag()

	// Appends a new value to the buffer, trimming it down to the given capacity
	// if necessary.
	mutating func addValue(value: Value, upToCapacity capacity: Int) {
		values.append(value)

		let overflow = values.count - capacity
		if overflow > 0 {
			values.removeRange(0..<overflow)
		}
	}
}
