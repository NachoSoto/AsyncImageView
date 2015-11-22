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

private typealias ViewType = AsyncImageView<TestRenderData, TestData, TestImageProvider>

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
				verifyImage(view.image, withSize: view.frame.size, data: view.data)
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
					expect(imageProvider.renderer.renderedImages.value) == [TestRenderData(data: view.data, size: view.frame.size)]
				}

				it("Only renders once if size does not change") {
					view.data = .A
					view.frame = CGRect(origin: CGPointZero, size: CGSize(width: 10, height: 10))
					view.frame = CGRect(origin: CGPoint(x: 1, y: 0), size: CGSize(width: 10, height: 10))

					expect(view.image).toNotEventually(beNil())
					expect(imageProvider.renderer.renderedImages.value) == [TestRenderData(data: view.data, size: view.frame.size)]
				}
			}
		}
	}
}

internal final class TestImageProvider: ImageProviderType {
	private let renderer = TestRenderer()

	func getImageForData(data: TestRenderData) -> SignalProducer<RenderResult, NoError> {
		let image = self.renderer.renderImageWithData(data)
		let result = RenderResult(image: image, cacheHit: true)

		return SignalProducer(value: result)
	}
}
