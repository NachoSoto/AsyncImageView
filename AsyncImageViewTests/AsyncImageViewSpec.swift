//
//  AsyncImageViewSpec.swift
//  AsyncImageViewTests
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import Quick
import Nimble
import ReactiveCocoa

@testable import AsyncImageView

private typealias ViewType = AsyncImageView<RenderData, Data, TestImageProvider>

class AsyncImageViewSpec: QuickSpec {
	override func spec() {
		describe("AsyncImageView") {
			var view: ViewType!
			var imageProvider: TestImageProvider!

			beforeEach {
				imageProvider = TestImageProvider()
				view = ViewType(
					initialFrame: CGRectZero,
					imageProvider: imageProvider,
					imageCreationScheduler: ImmediateScheduler()
				)
			}

			func verifyView() {
				expect(view.image).toNotEventually(beNil())

				guard let image = view.image else { return }

				expect(image.size) == view.frame.size
				expect(image.scale) == view.data.rawValue
			}

			it("has no image initially") {
				expect(view.image).to(beNil())
			}

			context("Updating image") {
				it("Does not render image if size is not set yet") {
					view.data = .A

					expect(view.image).to(beNil())
				}

				it("Updates image when setting data") {
					view.frame.size = CGSize(width: 10, height: 10)
					view.data = .A

					verifyView()
				}

				it("Updates image when updating data") {
					view.frame.size = CGSize(width: 10, height: 10)
					view.data = .A
					view.data = .B

					verifyView()
				}

				it("Updates image when setting frame") {
					view.data = .C
					view.frame.size = CGSize(width: 10, height: 10)

					verifyView()
				}

				it("Updates image when updating frame") {
					view.frame.size = CGSize(width: 10, height: 10)
					view.data = .C

					view.frame.size = CGSize(width: 15, height: 15)
					
					verifyView()
				}
			}

			context("Not updating image if nothing changed") {
				it("Does not attempt to render anything is size is not ready") {
					view.data = .A
					view.frame.size = CGSize(width: 10, height: 0)

					expect(view.image).toEventually(beNil())
				}

				it("Only renders once if data does not change") {
					view.data = .A
					view.frame.size = CGSize(width: 10, height: 10)
					view.data = .A

					expect(view.image).toNotEventually(beNil())
					expect(imageProvider.renderedImages) == [RenderData(data: view.data, size: view.frame.size)]
				}

				it("Only renders once if size does not change") {
					view.data = .A
					view.frame = CGRect(origin: CGPointZero, size: CGSize(width: 10, height: 10))
					view.frame = CGRect(origin: CGPoint(x: 1, y: 0), size: CGSize(width: 10, height: 10))

					expect(view.image).toNotEventually(beNil())
					expect(imageProvider.renderedImages) == [RenderData(data: view.data, size: view.frame.size)]
				}
			}
		}
	}
}

private enum Data: CGFloat, Hashable {
	case A = 1.0
	case B = 2.0
	case C = 3.0
}

extension Data: ImageViewDataType {
	var data: Data {
		return self
	}

	func renderDataWithSize(size: CGSize) -> RenderData {
		return RenderData(data: self.data, size: size)
	}
}

private struct RenderData: RenderDataType {
	let data: Data
	let size: CGSize

	var hashValue: Int {
		return data.hashValue * size.width.hashValue * size.height.hashValue
	}
}

private func ==(lhs: RenderData, rhs: RenderData) -> Bool {
	return (lhs.data == rhs.data &&
			lhs.size == rhs.size)
}

private final class TestImageProvider: ImageProviderType {
	var renderedImages: [RenderData] = []

	func getImageForData(data: RenderData) -> SignalProducer<RenderResult, NoError> {
		let image = TestImageProvider.imageOfSize(data.size, scale: data.data.rawValue)
		let result = RenderResult(image: image, cacheHit: true)

		return SignalProducer(value: result)
			.on(started: {
				self.renderedImages.append(data)
			})
	}

	private static func imageOfSize(size: CGSize, scale: CGFloat) -> UIImage {
		assert(size.width > 0 && size.height > 0, "Should not attempt to render with invalid size: \(size)")

		UIGraphicsBeginImageContextWithOptions(size, true, scale)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return image
	}
}
