//
//  TestRenderData.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa

import Quick
import Nimble

@testable import AsyncImageView

internal enum TestData: CGFloat, Hashable {
	case A = 1.0
	case B = 2.0
	case C = 3.0
}

extension TestData: ImageViewDataType {
	var data: TestData {
		return self
	}

	func renderDataWithSize(size: CGSize) -> TestRenderData {
		return RenderData(data: self.data, size: size)
	}
}

internal struct TestRenderData: RenderDataType {
	let data: TestData
	let size: CGSize

	var hashValue: Int {
		return data ^^^ size.width ^^^ size.height
	}
}

internal func ==(lhs: TestRenderData, rhs: TestRenderData) -> Bool {
	return (lhs.data == rhs.data &&
			lhs.size == rhs.size)
}

internal final class TestRenderer: RendererType {
	var renderedImages: Atomic<[TestRenderData]> = Atomic([])

	func renderImageWithData(data: TestRenderData) -> SignalProducer<UIImage, NoError> {
		return TestRenderer
			.rendererForSize(data.size, scale: data.data.rawValue)
			.asyncRenderer(ImmediateScheduler())
			.renderImageWithData(data)
			.on(started: {
				self.renderedImages.modify { $0 + [data] }
			})
	}

	static func rendererForSize(size: CGSize, scale: CGFloat) -> ContextRenderer<TestRenderData> {
		precondition(size.width > 0 && size.height > 0, "Should not attempt to render with invalid size: \(size)")

		return ContextRenderer<TestRenderData>(scale: scale, opaque: true) { _ in
			// nothing to render
		}
	}
}

internal func verifyImage(@autoclosure(escaping) image: () -> UIImage?, withSize size: CGSize, data: TestData?) {
	if let data = data {
		verifyImage(image, withSize: size, expectedScale: data.rawValue)
	} else {
		expect(image()).toEventually(beNil())
	}
}

internal func verifyImage(@autoclosure(escaping) image: () -> UIImage?, withSize size: CGSize, expectedScale: CGFloat) {
	expect(image()?.size).toEventually(equal(size))
	expect(image()?.scale).toEventually(equal(expectedScale))
}
