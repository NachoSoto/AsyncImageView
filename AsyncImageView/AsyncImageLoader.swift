//
//  AsyncImageLoader.swift
//  AsyncImageView
//
//  Created by Javier Soto on 5/1/20.
//  Copyright © 2020 Nacho Soto. All rights reserved.
//

import Combine

import ReactiveSwift

internal final class AsyncImageLoader<
    Data: RenderDataType,
    ImageViewData: ImageViewDataType,
    Renderer: RendererType,
    PlaceholderRenderer: RendererType
    >: ObservableObject
    where
    ImageViewData.RenderData == Data,
    Renderer.Data == Data,
    Renderer.Error == Never,
    PlaceholderRenderer.Data == Data,
    PlaceholderRenderer.Error == Never,
Renderer.RenderResult == PlaceholderRenderer.RenderResult {
    struct Request {
        let data: Data?
        var transition: ImageTransition = .automatic
        var placeholderPolicy: ImagePlaceholderPolicy = .standard
    }

    struct Update {
        let result: Renderer.RenderResult?
        let transition: ImageTransition
    }

    static func createSignal(
        requestsSignal: Signal<Data?, Never>,
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer?,
        uiScheduler: ReactiveSwift.Scheduler,
        imageCreationScheduler: ReactiveSwift.Scheduler = ImmediateScheduler()
    ) -> Signal<Renderer.RenderResult?, Never> {
        self.createSignal(
            requestsSignal: requestsSignal.map { Request(data: $0) },
            renderer: renderer,
            placeholderRenderer: placeholderRenderer,
            uiScheduler: uiScheduler,
            imageCreationScheduler: imageCreationScheduler
        ).map(\.result)
    }

    static func createSignal(
        requestsSignal: Signal<Request, Never>,
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer?,
        uiScheduler: ReactiveSwift.Scheduler,
        imageCreationScheduler: ReactiveSwift.Scheduler = ImmediateScheduler()
    ) -> Signal<Update, Never> {
        requestsSignal.skipRepeats { $0.data == $1.data }
            .flatMap(.latest) { request -> SignalProducer<Update, Never> in
                guard request.data != nil else {
                    return SignalProducer(value: Update(result: nil, transition: request.transition))
                }
                // Switch requests synchronously; only rendering waits for the creation scheduler.
                return SignalProducer { observer, lifetime in
                    lifetime += self.render(
                        request,
                        renderer: renderer,
                        placeholderRenderer: placeholderRenderer,
                        uiScheduler: uiScheduler
                    )
                    .map { Update(result: $0, transition: request.transition) }
                    .start(observer)
                }
                .start(on: imageCreationScheduler)
                // A replaced request must also cancel results waiting for the main thread.
                .observe(on: SynchronousUIScheduler())
            }
    }

    private static func render(
        _ request: Request,
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer?,
        uiScheduler: ReactiveSwift.Scheduler
    ) -> SignalProducer<Renderer.RenderResult?, Never> {
        guard let data = request.data else { return SignalProducer(value: nil) }
        if let placeholderRenderer {
            let placeholder = request.placeholderPolicy == .keepCurrentImage
                ? SignalProducer<Renderer.RenderResult, Never>.empty
                : placeholderRenderer.renderImageWithData(data)
            return placeholder
                .observe(on: uiScheduler)
                .take(
                    // Preserve the source's delivery timing; only the placeholder uses uiScheduler here.
                    // Keep listening if rendering completes without a value (for example, on failure).
                    untilReplacement: renderer.renderImageWithData(data).concat(.never)
                )
                .map(Optional.some)
        } else {
            let image = renderer.renderImageWithData(data)
                .observe(on: uiScheduler)
                .map(Optional.some)
            return request.placeholderPolicy == .keepCurrentImage ? image : image.prefix(value: nil)
        }
    }
}
