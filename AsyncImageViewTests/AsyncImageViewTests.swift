//
//  AsyncImageViewTests.swift
//  AsyncImageViewTests
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift
import Testing

import AsyncImageView

@Suite(.serialized) @MainActor
struct AsyncImageViewBehaviorTests {
	@Test
	func hasNoImageInitially() {
		let fixture = ImageViewFixture()

		#expect(fixture.view.image == nil)
	}

	@Test
	func doesNotRenderUntilSizeIsAvailable() {
		let fixture = ImageViewFixture()

		fixture.view.data = .a

		#expect(fixture.view.image == nil)
		#expect(fixture.renderer.renderedImages.value.isEmpty)
	}

	@Test
	func settingDataUpdatesImage() async {
		let fixture = ImageViewFixture(size: CGSize(width: 10, height: 10))

		fixture.view.data = .a

		await fixture.verifyRenderedImage()
	}

	@Test
	func updatingDataUpdatesImage() async {
		let fixture = ImageViewFixture(size: CGSize(width: 10, height: 10))

		fixture.view.data = .a
		fixture.view.data = .b

		await fixture.verifyRenderedImage()
	}

	@Test
	func settingFrameUpdatesImage() async {
		let fixture = ImageViewFixture()

		fixture.view.data = .c
		fixture.view.frame.size = CGSize(width: 10, height: 10)

		await fixture.verifyRenderedImage()
	}

	@Test
	func changingFrameSizeUpdatesImage() async {
		let fixture = ImageViewFixture(size: CGSize(width: 10, height: 10), data: .c)

		fixture.view.frame.size = CGSize(width: 15, height: 15)

		await fixture.verifyRenderedImage()
	}

	@Test
	func changingBoundsSizeUpdatesImage() async {
		let fixture = ImageViewFixture(size: CGSize(width: 10, height: 10), data: .c)

		fixture.view.bounds.size = CGSize(width: 15, height: 15)

		await fixture.verifyRenderedImage()
	}

	@Test
	func updatingDataResetsImageBeforeRenderingReplacement() async {
		let fixture = ImageViewFixture(size: CGSize(width: 10, height: 10), data: .c)
		await fixture.verifyRenderedImage()

		fixture.view.data = .a

		#expect(fixture.view.image == nil)
		await fixture.verifyRenderedImage()
	}

	@Test
	func updatingFrameResetsImageBeforeRenderingReplacement() async {
		let fixture = ImageViewFixture(size: CGSize(width: 10, height: 10), data: .c)
		await fixture.verifyRenderedImage()

		fixture.view.frame.size = CGSize(width: 15, height: 15)

		#expect(fixture.view.image == nil)
		await fixture.verifyRenderedImage()
	}

	@Test
	func settingDataToNilResetsImage() async {
		let fixture = ImageViewFixture(size: CGSize(width: 10, height: 10), data: .c)
		await fixture.verifyRenderedImage()

		fixture.view.data = nil

		#expect(fixture.view.image == nil)
	}

	@Test
	func invalidSizeDoesNotRender() async {
		let fixture = ImageViewFixture()

		fixture.view.data = .a
		fixture.view.frame.size = CGSize(width: 10, height: 0)

		let didRender = await eventuallyOnMainActor { fixture.view.image != nil }
		#expect(!didRender)
		#expect(fixture.renderer.renderedImages.value.isEmpty)
	}

	@Test
	func unchangedDataRendersOnlyOnce() async {
		let fixture = ImageViewFixture()

		fixture.view.data = .a
		fixture.view.frame.size = CGSize(width: 10, height: 10)
		fixture.view.data = .a

		await fixture.verifySingleRender()
	}

	@Test
	func unchangedSizeRendersOnlyOnce() async {
		let fixture = ImageViewFixture()

		fixture.view.data = .a
		fixture.view.frame = CGRect(origin: .zero, size: CGSize(width: 10, height: 10))
		fixture.view.frame.origin.x = 1

		await fixture.verifySingleRender()
	}

	@Test
	func placeholderThenRealImageAreDisplayedInOrder() async {
		let fixture = PlaceholderFixture()
		let renderData = fixture.prepare(.a)

		fixture.view.data = .a
		#expect(fixture.view.image == nil)

		fixture.placeholderRenderer.emitImage(for: renderData, scale: TestData.a.placeholderScale)
		await fixture.verifyPlaceholder()

		fixture.renderer.emitImage(for: renderData, scale: TestData.a.rawValue)
		await fixture.verifyRealImage()
	}

	@Test
	func updatingDataKeepsPreviousPlaceholderUntilReplacementArrives() async {
		let fixture = PlaceholderFixture()
		let originalRenderData = fixture.prepare(.a)
		_ = fixture.prepare(.b)
		fixture.view.data = .a

		fixture.placeholderRenderer.emitImage(for: originalRenderData, scale: TestData.a.placeholderScale)
		await fixture.verifyPlaceholder()

		fixture.view.data = .b

		await fixture.verifyPlaceholder(scale: TestData.a.placeholderScale)
	}

	@Test
	func updatingDataDisplaysNewPlaceholder() async {
		let fixture = PlaceholderFixture()
		let originalRenderData = fixture.prepare(.a)
		let updatedRenderData = fixture.prepare(.b)
		fixture.view.data = .a
		fixture.renderer.emitImage(for: originalRenderData, scale: TestData.a.rawValue)
		await fixture.verifyRealImage()

		fixture.view.data = .b
		fixture.placeholderRenderer.emitImage(for: updatedRenderData, scale: TestData.b.placeholderScale)

		await fixture.verifyPlaceholder()
	}

	@Test
	func placeholderViewResetsImageWhenDataBecomesNil() async {
		let fixture = PlaceholderFixture(size: CGSize(width: 10, height: 10))
		let renderData = fixture.prepare(.a)
		fixture.view.data = .a
		fixture.renderer.emitImage(for: renderData, scale: TestData.a.rawValue)
		await fixture.verifyRealImage()

		fixture.view.data = nil

		#expect(fixture.view.image == nil)
	}

	@Test
	func placeholderDisplaysIfMainRendererCompletesFirst() async {
		let fixture = PlaceholderFixture()
		let renderData = fixture.prepare(.a)
		fixture.view.data = .a

		fixture.renderer.complete(renderData)
		fixture.placeholderRenderer.emitImage(for: renderData, scale: TestData.a.placeholderScale)

		await fixture.verifyPlaceholder()
	}

	@Test
	func completingMainRendererDoesNotResetDisplayedPlaceholder() async {
		let fixture = PlaceholderFixture()
		let renderData = fixture.prepare(.a)
		fixture.view.data = .a
		fixture.placeholderRenderer.emitImage(for: renderData, scale: TestData.a.placeholderScale)
		await fixture.verifyPlaceholder()

		fixture.renderer.complete(renderData)

		await fixture.verifyPlaceholder()
	}
}

@MainActor
private final class ImageViewFixture {
	typealias ViewType = AsyncImageView<TestRenderData, TestData, TestRenderer, TestRenderer>

	let renderer = TestRenderer()
	let view: ViewType
	private let window = UIWindow()

	init(size: CGSize = .zero, data: TestData? = nil) {
		self.view = ViewType(
			initialFrame: CGRect(origin: .zero, size: size),
			renderer: self.renderer,
			placeholderRenderer: nil,
			uiScheduler: QueueScheduler(targeting: DispatchQueue.main),
			imageCreationScheduler: ImmediateScheduler()
		)
		self.window.addSubview(self.view)
		self.view.data = data
	}

	func verifyRenderedImage() async {
		await verifyImage(
			self.view.image,
			withSize: self.view.frame.size,
			data: self.view.data
		)
	}

	func verifySingleRender() async {
		await self.verifyRenderedImage()
		#expect(
			self.renderer.renderedImages.value == [
				TestRenderData(data: self.view.data!, size: self.view.frame.size)
			]
		)
	}
}

@MainActor
private final class PlaceholderFixture {
	typealias ViewType = AsyncImageView<TestRenderData, TestData, ManualRenderer, ManualRenderer>

	let placeholderRenderer = ManualRenderer()
	let renderer = ManualRenderer()
	let view: ViewType
	private let window = UIWindow()

	init(size: CGSize = CGSize(width: 1, height: 1)) {
		self.view = ViewType(
			initialFrame: CGRect(origin: .zero, size: size),
			renderer: self.renderer,
			placeholderRenderer: self.placeholderRenderer,
			uiScheduler: QueueScheduler(targeting: DispatchQueue.main),
			imageCreationScheduler: ImmediateScheduler()
		)
		self.window.addSubview(self.view)
	}

	func prepare(_ data: TestData) -> TestRenderData {
		let renderData = data.renderDataWithSize(self.view.frame.size)
		self.placeholderRenderer.addSignal(for: renderData)
		self.renderer.addSignal(for: renderData)
		return renderData
	}

	func verifyRealImage() async {
		await verifyImage(
			self.view.image,
			withSize: self.view.frame.size,
			data: self.view.data!
		)
	}

	func verifyPlaceholder(scale: CGFloat? = nil) async {
		await verifyImage(
			self.view.image,
			withSize: self.view.frame.size,
			expectedScale: scale ?? self.view.data!.placeholderScale
		)
	}
}

private final class ManualRenderer: RendererType {
	private var signals: [
		TestRenderData: (
			output: Signal<UIImage, Never>,
			input: Signal<UIImage, Never>.Observer
		)
	] = [:]

	func addSignal(for data: TestRenderData) {
		self.signals[data] = Signal<UIImage, Never>.pipe()
	}

	func emitImage(for data: TestRenderData, scale: CGFloat) {
		let image = TestRenderer.rendererForSize(data.size, scale: scale)
			.renderImageWithData(data)
		let observer = self.observer(for: data)

		observer.send(value: image)
		observer.sendCompleted()
	}

	func complete(_ data: TestRenderData) {
		// AsyncImageView renderers cannot fail, so failure is represented by
		// completing without producing an image.
		self.observer(for: data).sendCompleted()
	}

	func renderImageWithData(_ data: TestRenderData) -> SignalProducer<UIImage, Never> {
		guard let signal = self.signals[data]?.output else {
			Issue.record("Signal not created for \(data)")
			return .empty
		}

		return SignalProducer(signal)
	}

	private func observer(for data: TestRenderData) -> Signal<UIImage, Never>.Observer {
		guard let observer = self.signals[data]?.input else {
			preconditionFailure("Signal not created for \(data)")
		}

		return observer
	}
}

private extension TestData {
	var placeholderScale: CGFloat {
		self.rawValue * 5
	}
}
