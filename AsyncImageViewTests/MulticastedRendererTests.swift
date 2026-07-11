//
//  MulticastedRendererTests.swift
//  AsyncImageViewTests
//
//  Created by Nacho Soto on 7/11/26.
//  Copyright © 2026 Nacho Soto. All rights reserved.
//

import Foundation
import Testing
import UIKit

import ReactiveSwift

@testable import AsyncImageView

@Suite
struct MulticastedRendererTests {
	@Test
	func rendersDifferentKeysConcurrently() {
		let source = BlockingRenderer()
		let renderer = UncheckedSendable(source.multicasted())
		let group = DispatchGroup()
		let queue = DispatchQueue(label: #function, attributes: .concurrent)

		for identifier in 0..<2 {
			group.enter()
			queue.async {
				let data = MulticastRenderData(identifier: identifier)
				_ = renderer.value.renderImageWithData(data).single()
				group.leave()
			}
		}

		let firstStarted = source.started.wait(timeout: .now() + 2)
		let secondStarted = source.started.wait(timeout: .now() + 2)
		source.release.signal()
		source.release.signal()
		let completed = group.wait(timeout: .now() + 2)

		#expect(firstStarted == .success)
		#expect(secondStarted == .success)
		#expect(completed == .success)
	}

	@Test
	func preservesTheLatestValueFromAMultiValueRenderer() throws {
		let firstImage = makeImage(size: CGSize(width: 16, height: 16))
		let secondImage = makeImage(size: CGSize(width: 32, height: 32))
		let source = MultiValueRenderer()
		let renderer = source.multicasted()
		let data = MulticastRenderData(identifier: 1)
		var initial: ImageResult?
		let disposable = renderer.renderImageWithData(data).startWithValues { initial = $0 }
		defer { disposable.dispose() }

		source.observer.send(value: firstImage)
		let firstHit = try #require(renderer.renderImageWithData(data).single()?.get())

		source.observer.send(value: secondImage)
		let secondHit = try #require(renderer.renderImageWithData(data).single()?.get())

		source.observer.sendCompleted()
		let completedHit = try #require(renderer.renderImageWithData(data).single()?.get())

		#expect(source.renderCount == 1)
		#expect(initial?.image === firstImage)
		#expect(initial?.cacheHit == false)
		#expect(firstHit.image === firstImage)
		#expect(firstHit.cacheHit == true)
		#expect(secondHit.image === secondImage)
		#expect(secondHit.cacheHit == true)
		#expect(completedHit.image === secondImage)
		#expect(completedHit.cacheHit == true)
	}

	@Test
	func sharesOneUpstreamRenderBetweenConcurrentWaiters() throws {
		let image = makeImage()
		let source = MultiValueRenderer()
		let renderer = source.multicasted()
		let data = MulticastRenderData(identifier: 1)
		let firstProducer = renderer.renderImageWithData(data)
		let secondProducer = renderer.renderImageWithData(data)
		var first: ImageResult?
		var second: ImageResult?
		let firstDisposable = firstProducer.startWithValues { first = $0 }
		let secondDisposable = secondProducer.startWithValues { second = $0 }
		defer {
			firstDisposable.dispose()
			secondDisposable.dispose()
		}

		source.observer.send(value: image)
		source.observer.sendCompleted()

		let firstResult = try #require(first)
		let secondResult = try #require(second)
		#expect(source.renderCount == 1)
		#expect(firstResult.image === image)
		#expect(secondResult.image === image)
		#expect(firstResult.cacheHit == false)
		#expect(secondResult.cacheHit == false)
	}

	@Test
	func retriesAfterANonCacheableResult() throws {
		let source = RecoveringRenderer()
		let renderer = source.multicasted()
		let data = MulticastRenderData(identifier: 1)

		let failed = try #require(renderer.renderImageWithData(data).single()?.get())
		let recovered = try #require(renderer.renderImageWithData(data).single()?.get())
		let cached = try #require(renderer.renderImageWithData(data).single()?.get())

		#expect(source.renderCount == 2)
		#expect(failed.cacheHit == false)
		#expect(failed.shouldCache == false)
		#expect(recovered.shouldCache == true)
		#expect(cached.cacheHit == true)
	}

	@Test
	func retriesAfterTheUpstreamCompletesWithoutAValue() throws {
		let source = EmptyThenValueRenderer()
		let renderer = source.multicasted()
		let data = MulticastRenderData(identifier: 1)

		let empty = renderer.renderImageWithData(data).single()
		let recovered = try #require(renderer.renderImageWithData(data).single()?.get())
		let cached = try #require(renderer.renderImageWithData(data).single()?.get())

		#expect(empty == nil)
		#expect(source.renderCount == 2)
		#expect(recovered.image === source.image)
		#expect(cached.image === source.image)
		#expect(cached.cacheHit == true)
	}
}

private struct MulticastRenderData: RenderDataType, Sendable {
	let identifier: Int
	let size = CGSize(width: 8, height: 8)
}

private struct UncheckedSendable<Value>: @unchecked Sendable {
	let value: Value

	init(_ value: Value) {
		self.value = value
	}
}

private final class BlockingRenderer: RendererType, @unchecked Sendable {
	let started = DispatchSemaphore(value: 0)
	let release = DispatchSemaphore(value: 0)

	private let image = makeImage()

	func renderImageWithData(_ data: MulticastRenderData) -> SignalProducer<UIImage, Never> {
		return SignalProducer { [image = self.image, release = self.release, started = self.started] observer, lifetime in
			started.signal()
			release.wait()

			guard !lifetime.hasEnded else { return }

			observer.send(value: image)
			observer.sendCompleted()
		}
	}
}

private final class MultiValueRenderer: RendererType {
	let signal: Signal<UIImage, Never>
	let observer: Signal<UIImage, Never>.Observer
	private(set) var renderCount = 0

	init() {
		(self.signal, self.observer) = Signal.pipe()
	}

	func renderImageWithData(_ data: MulticastRenderData) -> SignalProducer<UIImage, Never> {
		self.renderCount += 1

		return self.signal.producer
	}
}

private final class RecoveringRenderer: RendererType {
	private let image = makeImage()
	private let scheduler = QueueScheduler(name: "MulticastedRendererTests.RecoveringRenderer")
	private(set) var renderCount = 0

	func renderImageWithData(_ data: MulticastRenderData) -> SignalProducer<ImageResult, Never> {
		self.renderCount += 1
		let result = ImageResult(
			image: self.image,
			cacheHit: false,
			shouldCache: self.renderCount > 1
		)

		return SignalProducer(value: result)
			.start(on: self.scheduler)
	}
}

private final class EmptyThenValueRenderer: RendererType {
	let image = makeImage()
	private(set) var renderCount = 0

	func renderImageWithData(_ data: MulticastRenderData) -> SignalProducer<UIImage, Never> {
		self.renderCount += 1

		return self.renderCount == 1
			? SignalProducer.empty
			: SignalProducer(value: self.image)
	}
}

private func makeImage(size: CGSize = CGSize(width: 8, height: 8)) -> UIImage {
	return UIGraphicsImageRenderer(size: size).image { _ in }
}
