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

class AsyncImageViewSpec: QuickSpec {
	override func spec() {
		describe("AsyncImageView") {
			context("No placeholder") {
				typealias ViewType = AsyncImageView<TestRenderData, TestData, TestRenderer>

				var view: ViewType!
				var renderer: TestRenderer!

				beforeEach {
					renderer = TestRenderer()
					view = ViewType(
						initialFrame: CGRectZero,
						renderer: renderer,
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
					it("does not render image if size is not set yet") {
						view.data = .A

						expect(view.image).to(beNil())
					}

					it("updates image when setting data") {
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .A

						verifyView()
					}

					it("updates image when updating data") {
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .A
						view.data = .B

						verifyView()
					}

					it("updates image when setting frame") {
						view.data = .C
						view.frame.size = CGSize(width: 10, height: 10)

						verifyView()
					}

					it("updates image when updating frame") {
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .C

						view.frame.size = CGSize(width: 15, height: 15)

						verifyView()
					}

					it("resets image when updating data") {
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .C
						verifyView()

						view.data = .A

						expect(view.image).to(beNil()) // image should be reset immediately
						verifyView() // and updated when rendering finishes
					}

					it("resets image when updating frame") {
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .C
						verifyView()

						view.frame.size = CGSize(width: 15, height: 15)

						expect(view.image).to(beNil()) // image should be reset immediately
						verifyView() // and updated when rendering finishes
					}
				}

				context("Not updating image if nothing changed") {
					it("does not attempt to render anything is size is not ready") {
						view.data = .A
						view.frame.size = CGSize(width: 10, height: 0)

						expect(view.image).toEventually(beNil())
					}

					it("only renders once if data does not change") {
						view.data = .A
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .A

						expect(view.image).toNotEventually(beNil())
						expect(renderer.renderedImages.value) == [TestRenderData(data: view.data, size: view.frame.size)]
					}

					it("only renders once if size does not change") {
						view.data = .A
						view.frame = CGRect(origin: CGPointZero, size: CGSize(width: 10, height: 10))
						view.frame = CGRect(origin: CGPoint(x: 1, y: 0), size: CGSize(width: 10, height: 10))

						expect(view.image).toNotEventually(beNil())
						expect(renderer.renderedImages.value) == [TestRenderData(data: view.data, size: view.frame.size)]
					}
				}
			}
		}
	}
}
