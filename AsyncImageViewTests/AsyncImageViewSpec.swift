//
//  AsyncImageViewSpec.swift
//  AsyncImageViewTests
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import Quick
import Nimble
import UIKit
import XCTest

import ReactiveSwift

import AsyncImageView

class AsyncImageViewSpec: QuickSpec {
	override class func spec() {
		describe("AsyncImageView") {
            // To ensure that updating UI takes one extra cycle
            // and we can verify image is reset before that
            let uiScheduler = QueueScheduler(targeting: DispatchQueue.main)
            var window: UIWindow!

            beforeEach {
                window = UIWindow()
            }

			context("No placeholder") {
				typealias ViewType = AsyncImageView<TestRenderData, TestData, TestRenderer, TestRenderer>

				var view: ViewType!
				var renderer: TestRenderer!

				beforeEach {
					renderer = TestRenderer()
					view = ViewType(
						initialFrame: .zero,
						renderer: renderer,
						placeholderRenderer: nil,
                        uiScheduler: uiScheduler,
                        imageCreationScheduler: ImmediateScheduler()
					)
                    window.addSubview(view)
				}

					func verifyView(
						file: FileString = #file,
						line: UInt = #line
					) {
						verifyImage(
							view.image,
							withSize: view.frame.size,
							data: view.data,
							file: file,
							line: line
						)
					}

				it("has no image initially") {
					expect(view.image).to(beNil())
				}

				context("Updating image") {
					it("does not render image if size is not set yet") {
						view.data = .a

						expect(view.image).to(beNil())
					}

					it("updates image when setting data") {
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .a

						verifyView()
					}

					it("updates image when updating data") {
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .a
						view.data = .b

						verifyView()
					}

					it("updates image when setting frame") {
						view.data = .c
						view.frame.size = CGSize(width: 10, height: 10)

						verifyView()
					}

					it("updates image when updating frame") {
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .c

						view.frame.size = CGSize(width: 15, height: 15)

						verifyView()
					}

					it("updates image when updating bounds") {
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .c

						view.bounds.size = CGSize(width: 15, height: 15)

						verifyView()
					}

					it("resets image when updating data") {
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .c
						verifyView()

						view.data = .a

						expect(view.image).to(beNil()) // image should be reset immediately
						verifyView() // and updated when rendering finishes
					}

					it("resets image when updating frame") {
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .c
						verifyView()

						view.frame.size = CGSize(width: 15, height: 15)

						expect(view.image).to(beNil()) // image should be reset immediately
						verifyView() // and updated when rendering finishes
					}

					it("resets image when setting data to nil") {
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .c

						verifyView()

						view.data = nil
						expect(view.image).to(beNil()) // image should be reset immediately
					}
				}

				context("Not updating image if nothing changed") {
					it("does not attempt to render anything is size is not ready") {
						view.data = .a
						view.frame.size = CGSize(width: 10, height: 0)

						expect(view.image).toEventually(beNil())
					}

					it("only renders once if data does not change") {
						view.data = .a
						view.frame.size = CGSize(width: 10, height: 10)
						view.data = .a

						expect(view.image).toNotEventually(beNil())
						expect(renderer.renderedImages.value) == [TestRenderData(data: view.data!, size: view.frame.size)]
					}

					it("only renders once if size does not change") {
						view.data = .a
						view.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 10, height: 10))
						view.frame = CGRect(origin: CGPoint(x: 1, y: 0), size: CGSize(width: 10, height: 10))

						expect(view.image).toNotEventually(beNil())
						expect(renderer.renderedImages.value) == [TestRenderData(data: view.data!, size: view.frame.size)]
					}
				}
			}

			context("Placeholder renderer") {
				typealias ViewType = AsyncImageView<TestRenderData, TestData, ManualRenderer, ManualRenderer>

				var view: ViewType!
				var placeholderRenderer: ManualRenderer!
				var renderer: ManualRenderer!

				beforeEach {
					placeholderRenderer = ManualRenderer()
					renderer = ManualRenderer()
					view = ViewType(
						initialFrame: CGRect.zero,
						renderer: renderer,
						placeholderRenderer: placeholderRenderer,
                        uiScheduler: uiScheduler,
						imageCreationScheduler: ImmediateScheduler()
					)
                    window.addSubview(view)
				}

					func verifyRealImage(
						file: FileString = #file,
						line: UInt = #line
					) {
						verifyImage(
							view.image,
							withSize: view.frame.size,
							data: view.data!,
							file: file,
							line: line
						)
					}

					func verifyPlaceholder(
						file: FileString = #file,
						line: UInt = #line
					) {
						verifyImage(
							view.image,
							withSize: view.frame.size,
							expectedScale: view.data!.placeholderScale,
							file: file,
							line: line
						)
					}

				it("has no image initially") {
					expect(view.image).to(beNil())
				}

				it("sets placeholder image if emitted first") {
					view.frame.size = CGSize(width: 1, height: 1)

					let data: TestData = .a
					let renderData = data.renderDataWithSize(view.frame.size)

					placeholderRenderer.addRenderSignal(renderData)
					renderer.addRenderSignal(renderData)

					view.data = data
					expect(view.image).to(beNil())

					placeholderRenderer.emitImageForData(renderData, scale: data.placeholderScale)
					verifyPlaceholder()

					renderer.emitImageForData(renderData, scale: data.rawValue)
					verifyRealImage()
				}

				it("does not clear placeholder image when updating data") {
					view.frame.size = CGSize(width: 1, height: 1)

					let originalData: TestData = .a
					let originalRenderData = originalData.renderDataWithSize(view.frame.size)

					let updatedData: TestData = .b
					let updatedRenderData = updatedData.renderDataWithSize(view.frame.size)

					placeholderRenderer.addRenderSignal(originalRenderData)
					placeholderRenderer.addRenderSignal(updatedRenderData)
					renderer.addRenderSignal(originalRenderData)
					renderer.addRenderSignal(updatedRenderData)

					view.data = originalData

					placeholderRenderer.emitImageForData(originalRenderData, scale: originalData.placeholderScale)
					verifyPlaceholder()

					view.data = updatedData
					verifyImage(view.image, withSize: view.frame.size, expectedScale: originalData.placeholderScale)
				}

				it("sets placeholder image when updating data") {
					view.frame.size = CGSize(width: 1, height: 1)

					let originalData: TestData = .a
					let originalRenderData = originalData.renderDataWithSize(view.frame.size)

					let updatedData: TestData = .b
					let updatedRenderData = updatedData.renderDataWithSize(view.frame.size)

					placeholderRenderer.addRenderSignal(originalRenderData)
					placeholderRenderer.addRenderSignal(updatedRenderData)
					renderer.addRenderSignal(originalRenderData)
					renderer.addRenderSignal(updatedRenderData)

					view.data = originalData

					renderer.emitImageForData(originalRenderData, scale: originalData.rawValue)
					verifyRealImage()

					view.data = updatedData

					placeholderRenderer.emitImageForData(updatedRenderData, scale: updatedData.placeholderScale)
					verifyPlaceholder()
				}

				it("resets image when setting data to nil") {
					view.frame.size = CGSize(width: 10, height: 10)

					let data: TestData = .a
					let renderData = data.renderDataWithSize(view.frame.size)

					placeholderRenderer.addRenderSignal(renderData)
					renderer.addRenderSignal(renderData)

					view.data = data

					renderer.emitImageForData(renderData, scale: data.rawValue)
					verifyRealImage()

					view.data = nil
					expect(view.image).to(beNil()) // image should be reset immediately
				}

                it("shows placeholder if renderer fails first") {
                    view.frame.size = CGSize(width: 1, height: 1)

                    let data: TestData = .a
                    let renderData = data.renderDataWithSize(view.frame.size)

                    placeholderRenderer.addRenderSignal(renderData)
                    renderer.addRenderSignal(renderData)

                    view.data = data

                    renderer.failAndComplete(renderData)

                    placeholderRenderer.emitImageForData(renderData, scale: data.placeholderScale)
                    verifyPlaceholder()
                }

                it("does not reset placeholder if renderer fails after") {
                    view.frame.size = CGSize(width: 1, height: 1)

                    let data: TestData = .a
                    let renderData = data.renderDataWithSize(view.frame.size)

                    placeholderRenderer.addRenderSignal(renderData)
                    renderer.addRenderSignal(renderData)

                    view.data = data

                    placeholderRenderer.emitImageForData(renderData, scale: data.placeholderScale)
                    verifyPlaceholder()

                    renderer.failAndComplete(renderData)
                    verifyPlaceholder()
                }
			}
		}
	}
}

private final class ManualRenderer: RendererType {
	var signals: [TestRenderData: (output: Signal<UIImage, Never>, input: Signal<UIImage, Never>.Observer)] = [:]

	func addRenderSignal(_ data: TestRenderData) {
		signals[data] = Signal<UIImage, Never>.pipe()
	}

    private func observer(forData data: TestRenderData) -> Signal<UIImage, Never>.Observer {
        return signals[data]!.input
    }

	func emitImageForData(_ data: TestRenderData, scale: CGFloat) {
        let image = TestRenderer.rendererForSize(data.size,
                                                 scale: scale)
            .renderImageWithData(data)
        let observer = self.observer(forData: data)

		observer.send(value: image)
		observer.sendCompleted()
	}

    func failAndComplete(_ data: TestRenderData) {
        // Errors aren't allowed in AsyncImageView (they must be handled prior),
        // so they instead simply cause the signal to complete.
        self.observer(forData: data).sendCompleted()
    }

	func renderImageWithData(_ data: TestRenderData) -> SignalProducer<UIImage, Never> {
		guard let signal = signals[data]?.output else {
			XCTFail("Signal not created for \(data)")
			return .empty
		}

        return SignalProducer(signal)
	}
}

private extension TestData {
	var placeholderScale: CGFloat {
		return self.rawValue * 5
	}
}
