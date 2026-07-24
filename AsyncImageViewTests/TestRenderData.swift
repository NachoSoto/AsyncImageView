//
//  TestRenderData.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift
import Testing

import AsyncImageView

internal enum TestData: CGFloat, Hashable {
	case a = 1.0
	case b = 2.0
	case c = 3.0
}

extension TestData: ImageViewDataType {
	var data: TestData {
		self
	}

	func renderDataWithSize(_ size: CGSize) -> TestRenderData {
		RenderData(data: self.data, size: size)
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

internal func == (lhs: TestRenderData, rhs: TestRenderData) -> Bool {
	return (lhs.data == rhs.data &&
			lhs.size == rhs.size)
}

internal final class TestRenderer: RendererType {
	var renderedImages: Atomic<[TestRenderData]> = Atomic([])

    func renderImageWithData(_ data: TestRenderData) -> SignalProducer<UIImage, Never> {
        TestRenderer.rendererForSize(data.size, scale: data.data.rawValue)
            .asyncRenderer(ImmediateScheduler())
            .renderImageWithData(data)
            .on(started: {
                self.renderedImages.modify { $0.append(data) }
            })
	}

    @available(iOS 10.0, tvOSApplicationExtension 10.0, *)
    static func rendererForSize(_ size: CGSize, scale: CGFloat) -> ContextRenderer<TestRenderData> {
		precondition(size.width > 0 && size.height > 0, "Should not attempt to render with invalid size: \(size)")

		return ContextRenderer<TestRenderData>(scale: scale, opaque: true) { _, _ in
			// nothing to render
		}
	}
}

@MainActor
internal func verifyImage(_ image: @autoclosure @escaping () -> UIImage?,
                          withSize size: CGSize,
                          data: TestData?) async {
	if let data = data {
		await verifyImage(
			image(),
			withSize: size,
			expectedScale: data.rawValue
		)
	} else {
        #expect(await eventuallyOnMainActor { image() == nil })
	}
}

@MainActor
internal func verifyImage(_ image: @autoclosure @escaping () -> UIImage?,
                          withSize size: CGSize,
                          expectedScale: CGFloat) async {
    #expect(await eventuallyOnMainActor { image()?.size == size })
	#expect(await eventuallyOnMainActor { image()?.scale == expectedScale })
}
