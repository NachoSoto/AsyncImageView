//
//  ImageInflaterRendererSpec.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/28/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import Quick
import Nimble
import RandomKit

@testable import AsyncImageView

class ImageInflaterRendererSpec: QuickSpec {
	override func spec() {
		describe("ImageInflaterRenderer") {
			context("Size Calculator") {
				it("returns identity frame if sizes match") {
					let size = CGSize.random()
					let result = InflaterSizeCalculator.drawingRectForRenderingImageOfSize(
						imageSize: size,
						inSize: size
					)

					expect(result) == CGRect(origin: CGPoint.zero, size: size)
				}
			}

			it("reduces size if aspect ratio matches, but canvas is smaller") {
				let imageSize = CGSize.random()
				let canvasSize = CGSize(width: imageSize.width * 0.4, height: imageSize.height * 0.4)

				let result = InflaterSizeCalculator.drawingRectForRenderingImageOfSize(
					imageSize: imageSize,
					inSize: canvasSize
				)

				expect(result) == CGRect(origin: CGPoint.zero, size: canvasSize)
			}

			it("scales up size if aspect ratio matches, but canvas is bigger") {
				let imageSize = CGSize.random()
				let canvasSize = CGSize(width: imageSize.width * 2, height: imageSize.height * 2)

				let result = InflaterSizeCalculator.drawingRectForRenderingImageOfSize(
					imageSize: imageSize,
					inSize: canvasSize
				)

				expect(result) == CGRect(origin: CGPoint.zero, size: canvasSize)
			}

			it("centers image horizontally if height matches, but canvas width is smaller") {
				let imageSize = CGSize(width: 1242, height: 240)
				let canvasSize = CGSize(width: 750, height: 240)

				let result = InflaterSizeCalculator.drawingRectForRenderingImageOfSize(
					imageSize: imageSize,
					inSize: canvasSize
				)

				expect(result.origin) == CGPoint(x: (imageSize.width - canvasSize.width) / -2.0, y: 0)
				expect(result.size) == imageSize
			}

			it("scales image and centers horizontally if height matches, but canvas width is bigger") {
				let imageSize = CGSize(width: 1242, height: 240)
				let canvasSize = CGSize(width: 1334, height: 240)

				let result = InflaterSizeCalculator.drawingRectForRenderingImageOfSize(
					imageSize: imageSize,
					inSize: canvasSize
				)

				let expectedHeight = canvasSize.height * (canvasSize.width / imageSize.width) // preserve aspect ratio

				expect(result.origin.x).to(beCloseTo(0))
				expect(result.origin.y).to(beCloseTo((canvasSize.height - expectedHeight) / 2.0))
				expect(result.size.width).to(beCloseTo(canvasSize.width))
				expect(result.size.height).to(beCloseTo(expectedHeight))
			}
			
			it("centers image vertically if width matches, but canvas height is smaller") {
				let imageSize = CGSize(width: 1242, height: 240)
				let canvasSize = CGSize(width: 1242, height: 100)

				let result = InflaterSizeCalculator.drawingRectForRenderingImageOfSize(
					imageSize: imageSize,
					inSize: canvasSize
				)

				expect(result.origin) == CGPoint(x: 0, y: (imageSize.height - canvasSize.height) / -2.0)
				expect(result.size) == imageSize
			}

			it("scales image and centers vertically if width matches, but canvas height is bigger") {
				let imageSize = CGSize(width: 1242, height: 240)
				let canvasSize = CGSize(width: 1242, height: 300)

				let result = InflaterSizeCalculator.drawingRectForRenderingImageOfSize(
					imageSize: imageSize,
					inSize: canvasSize
				)

				let expectedWidth = canvasSize.width * (canvasSize.height / imageSize.height) // preserve aspect ratio

				// TODO: write matcher for `CGRect`.
				expect(result.origin.x).to(beCloseTo((canvasSize.width - expectedWidth) / 2.0))
				expect(result.origin.y).to(beCloseTo(0))
				expect(result.size.width).to(beCloseTo(expectedWidth))
				expect(result.size.height).to(beCloseTo(canvasSize.height))
			}

			context("aspect ratio and image size are different") {
				context("image size is smaller") {
					it("image aspect ratio is smaller") {
						let imageSize = CGSize(width: 30, height: 40)
						let canvasSize = CGSize(width: 50, height: 60)

						let result = InflaterSizeCalculator.drawingRectForRenderingImageOfSize(
							imageSize: imageSize,
							inSize: canvasSize
						)

						expect(result.origin.x).to(beCloseTo(0))
						expect(result.origin.y).to(beCloseTo(-3.3333))
						expect(result.size.width).to(beCloseTo(50))
						expect(result.size.height).to(beCloseTo(66.6666))
					}

					it("image aspect ratio is bigger") {
						let imageSize = CGSize(width: 50, height: 60)
						let canvasSize = CGSize(width: 60, height: 80)

						let result = InflaterSizeCalculator.drawingRectForRenderingImageOfSize(
							imageSize: imageSize,
							inSize: canvasSize
						)

						expect(result.origin.x).to(beCloseTo(-3.3333))
						expect(result.origin.y).to(beCloseTo(0))
						expect(result.size.width).to(beCloseTo(66.6666))
						expect(result.size.height).to(beCloseTo(80))
					}
				}

				context("image size is bigger") {
					it("image aspect ratio is smaller") {
						let imageSize = CGSize(width: 60, height: 80)
						let canvasSize = CGSize(width: 50, height: 60)

						let result = InflaterSizeCalculator.drawingRectForRenderingImageOfSize(
							imageSize: imageSize,
							inSize: canvasSize
						)

						expect(result.origin.x).to(beCloseTo(0))
						expect(result.origin.y).to(beCloseTo(-3.3333))
						expect(result.size.width).to(beCloseTo(50))
						expect(result.size.height).to(beCloseTo(66.6666))
					}

					it("image aspect ratio is bigger") {
						let imageSize = CGSize(width: 100, height: 120)
						let canvasSize = CGSize(width: 60, height: 80)

						let result = InflaterSizeCalculator.drawingRectForRenderingImageOfSize(
							imageSize: imageSize,
							inSize: canvasSize
						)

						expect(result.origin.x).to(beCloseTo(-3.3333))
						expect(result.origin.y).to(beCloseTo(0))
						expect(result.size.width).to(beCloseTo(66.6666))
						expect(result.size.height).to(beCloseTo(80))
					}
				}
			}
		}
	}
}
