//
//  TestRenderData.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift

import Quick
import Nimble

import AsyncImageView

internal enum TestData: CGFloat, Hashable {
	case a = 1.0
	case b = 2.0
	case c = 3.0
}

extension TestData: ImageViewDataType {
	var data: TestData {
		return self
	}

	func renderDataWithSize(_ size: CGSize) -> TestRenderData {
		return RenderData(data: self.data, size: size)
	}
}

internal struct TestRenderData: RenderDataType {
	let data: TestData
	let size: CGSize

    func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(size.width)
        hasher.combine(size.height)
    }
}

internal func ==(lhs: TestRenderData, rhs: TestRenderData) -> Bool {
	return (lhs.data == rhs.data &&
			lhs.size == rhs.size)
}

internal final class TestRenderer: RendererType {
	var renderedImages: Atomic<[TestRenderData]> = Atomic([])

    func renderImageWithData(_ data: TestRenderData) -> SignalProducer<UIImage, Never> {
        return TestRenderer.rendererForSize(data.size, scale: data.data.rawValue)
            .asyncRenderer(ImmediateScheduler())
            .renderImageWithData(data)
            .on(started: {
                self.renderedImages.modify { $0.append(data) }
            })
	}

    @available(iOS 10.0, tvOSApplicationExtension 10.0,  *)
    static func rendererForSize(_ size: CGSize, scale: CGFloat) -> ContextRenderer<TestRenderData> {
		precondition(size.width > 0 && size.height > 0, "Should not attempt to render with invalid size: \(size)")

		return ContextRenderer<TestRenderData>(scale: scale, opaque: true) { _, _ in
			// nothing to render
		}
	}
}

internal func verifyImage(_ image: @autoclosure @escaping () -> UIImage?,
                          withSize size: CGSize,
                          data: TestData?,
                          file: FileString = #file,
                          line: UInt = #line) {
	if let data = data {
		verifyImage(image(),
                    withSize: size,
                    expectedScale: data.rawValue,
                    file: file,
                    line: line)
	} else {
        expect(file: file, line: line, image()).toEventually(beNil())
	}
}

internal func verifyImage(_ image: @autoclosure @escaping () -> UIImage?,
                          withSize size: CGSize,
                          expectedScale: CGFloat,
                          file: FileString = #file,
                          line: UInt = #line) {
    expect(file: file, line: line, image()?.size).toEventually(equal(size))
	expect(file: file, line: line, image()?.scale).toEventually(equal(expectedScale))
}
