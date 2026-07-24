//
//  ImageInflaterRendererTests.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/28/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import CoreGraphics
import UIKit

import Testing

@testable import AsyncImageView

@Suite
struct ImageInflaterRendererTests {
    @Test
    func failedBitmapContextCreationReturnsOriginalImage() {
        let image = UIImage()
        var didAttemptContextCreation = false
        var didRender = false

        let result = image.processImageWithBitmapContext(
            withSize: CGSize(width: 20, height: 30),
            scale: 2,
            opaque: false,
            contentMode: .aspectFill,
            bitmapContextFactory: { _, _, _, _, _ in
                didAttemptContextCreation = true
                return nil
            },
            renderingBlock: { _, _, _, _ in
                didRender = true
            }
        )

        #expect(didAttemptContextCreation)
        #expect(!didRender)
        #expect(result.image === image)
        #expect(!result.didProcess)
    }

    @Test(arguments: DrawingRectCase.aspectFitCases)
    func aspectFitDrawingRect(testCase: DrawingRectCase) {
        let result = InflaterSizeCalculator.drawingRectForRenderingWithAspectFit(
            imageSize: testCase.imageSize,
            inSize: testCase.canvasSize
        )

        #expect(result.isApproximatelyEqual(to: testCase.expected))
    }

    @Test(arguments: DrawingRectCase.aspectFillCases)
    func aspectFillDrawingRect(testCase: DrawingRectCase) {
        let result = InflaterSizeCalculator.drawingRectForRenderingWithAspectFill(
            imageSize: testCase.imageSize,
            inSize: testCase.canvasSize
        )

        #expect(result.isApproximatelyEqual(to: testCase.expected))
    }
}

struct DrawingRectCase: CustomStringConvertible {
    let description: String
    let imageSize: CGSize
    let canvasSize: CGSize
    let expected: CGRect

    init(
        _ description: String,
        imageSize: CGSize,
        canvasSize: CGSize,
        expected: CGRect
    ) {
        self.description = description
        self.imageSize = imageSize
        self.canvasSize = canvasSize
        self.expected = expected
    }

    static let aspectFitCases: [Self] = [
        Self(
            "matching sizes",
            imageSize: CGSize(width: 120, height: 80),
            canvasSize: CGSize(width: 120, height: 80),
            expected: CGRect(x: 0, y: 0, width: 120, height: 80)
        ),
        Self(
            "proportional reduction",
            imageSize: CGSize(width: 120, height: 80),
            canvasSize: CGSize(width: 48, height: 32),
            expected: CGRect(x: 0, y: 0, width: 48, height: 32)
        ),
        Self(
            "proportional enlargement",
            imageSize: CGSize(width: 120, height: 80),
            canvasSize: CGSize(width: 240, height: 160),
            expected: CGRect(x: 0, y: 0, width: 240, height: 160)
        ),
        Self(
            "narrower canvas with matching height",
            imageSize: CGSize(width: 1242, height: 240),
            canvasSize: CGSize(width: 750, height: 240),
            expected: CGRect(x: 0, y: 47.5362318841, width: 750, height: 144.9275362319)
        ),
        Self(
            "wider canvas with matching height",
            imageSize: CGSize(width: 1242, height: 240),
            canvasSize: CGSize(width: 1334, height: 240),
            expected: CGRect(x: 46, y: 0, width: 1242, height: 240)
        ),
        Self(
            "shorter canvas with matching width",
            imageSize: CGSize(width: 1242, height: 240),
            canvasSize: CGSize(width: 1242, height: 100),
            expected: CGRect(x: 362.25, y: 0, width: 517.5, height: 100)
        ),
        Self(
            "taller canvas with matching width",
            imageSize: CGSize(width: 1242, height: 240),
            canvasSize: CGSize(width: 1242, height: 300),
            expected: CGRect(x: 0, y: 30, width: 1242, height: 240)
        ),
        Self(
            "smaller image with narrower aspect ratio",
            imageSize: CGSize(width: 30, height: 40),
            canvasSize: CGSize(width: 50, height: 60),
            expected: CGRect(x: 2.5, y: 0, width: 45, height: 60)
        ),
        Self(
            "smaller image with wider aspect ratio",
            imageSize: CGSize(width: 50, height: 60),
            canvasSize: CGSize(width: 60, height: 80),
            expected: CGRect(x: 0, y: 4, width: 60, height: 72)
        ),
        Self(
            "larger image with narrower aspect ratio",
            imageSize: CGSize(width: 60, height: 80),
            canvasSize: CGSize(width: 50, height: 60),
            expected: CGRect(x: 2.5, y: 0, width: 45, height: 60)
        ),
        Self(
            "larger image with wider aspect ratio",
            imageSize: CGSize(width: 100, height: 120),
            canvasSize: CGSize(width: 60, height: 80),
            expected: CGRect(x: 0, y: 4, width: 60, height: 72)
        )
    ]

    static let aspectFillCases: [Self] = [
        Self(
            "matching sizes",
            imageSize: CGSize(width: 120, height: 80),
            canvasSize: CGSize(width: 120, height: 80),
            expected: CGRect(x: 0, y: 0, width: 120, height: 80)
        ),
        Self(
            "proportional reduction",
            imageSize: CGSize(width: 120, height: 80),
            canvasSize: CGSize(width: 48, height: 32),
            expected: CGRect(x: 0, y: 0, width: 48, height: 32)
        ),
        Self(
            "proportional enlargement",
            imageSize: CGSize(width: 120, height: 80),
            canvasSize: CGSize(width: 240, height: 160),
            expected: CGRect(x: 0, y: 0, width: 240, height: 160)
        ),
        Self(
            "narrower canvas with matching height",
            imageSize: CGSize(width: 1242, height: 240),
            canvasSize: CGSize(width: 750, height: 240),
            expected: CGRect(x: -246, y: 0, width: 1242, height: 240)
        ),
        Self(
            "wider canvas with matching height",
            imageSize: CGSize(width: 1242, height: 240),
            canvasSize: CGSize(width: 1334, height: 240),
            expected: CGRect(x: 0, y: -8.8888888889, width: 1334, height: 257.7777777778)
        ),
        Self(
            "shorter canvas with matching width",
            imageSize: CGSize(width: 1242, height: 240),
            canvasSize: CGSize(width: 1242, height: 100),
            expected: CGRect(x: 0, y: -70, width: 1242, height: 240)
        ),
        Self(
            "taller canvas with matching width",
            imageSize: CGSize(width: 1242, height: 240),
            canvasSize: CGSize(width: 1242, height: 300),
            expected: CGRect(x: -155.25, y: 0, width: 1552.5, height: 300)
        ),
        Self(
            "smaller image with narrower aspect ratio",
            imageSize: CGSize(width: 30, height: 40),
            canvasSize: CGSize(width: 50, height: 60),
            expected: CGRect(x: 0, y: -3.3333333333, width: 50, height: 66.6666666667)
        ),
        Self(
            "smaller image with wider aspect ratio",
            imageSize: CGSize(width: 50, height: 60),
            canvasSize: CGSize(width: 60, height: 80),
            expected: CGRect(x: -3.3333333333, y: 0, width: 66.6666666667, height: 80)
        ),
        Self(
            "larger image with narrower aspect ratio",
            imageSize: CGSize(width: 60, height: 80),
            canvasSize: CGSize(width: 50, height: 60),
            expected: CGRect(x: 0, y: -3.3333333333, width: 50, height: 66.6666666667)
        ),
        Self(
            "larger image with wider aspect ratio",
            imageSize: CGSize(width: 100, height: 120),
            canvasSize: CGSize(width: 60, height: 80),
            expected: CGRect(x: -3.3333333333, y: 0, width: 66.6666666667, height: 80)
        )
    ]
}
