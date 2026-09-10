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
        uiScheduler: ReactiveSwift.Scheduler
    ) -> Signal<Renderer.RenderResult?, Never> {
        self.createSignal(
            requestsSignal: requestsSignal.map { Request(data: $0) },
            renderer: renderer,
            placeholderRenderer: placeholderRenderer,
            uiScheduler: uiScheduler
        ).map(\.result)
    }

    static func createSignal(
        requestsSignal: Signal<Request, Never>,
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer?,
        uiScheduler: ReactiveSwift.Scheduler
    ) -> Signal<Update, Never> {
        requestsSignal.skipRepeats { $0.data == $1.data }
            .flatMap(.latest) { request -> SignalProducer<Update, Never> in
                self.render(
                    request,
                    renderer: renderer,
                    placeholderRenderer: placeholderRenderer,
                    uiScheduler: uiScheduler
                ).map { Update(result: $0, transition: request.transition) }
            }
            .observe(on: SynchronousUIScheduler())
    }

    private static func render(
        _ request: Request,
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer?,
        uiScheduler: ReactiveSwift.Scheduler
    ) -> SignalProducer<Renderer.RenderResult?, Never> {
        guard let data = request.data else { return SignalProducer(value: nil) }
        let image = renderer.renderImageWithData(data).observe(on: uiScheduler)

        if request.placeholderPolicy == .keepCurrentImage {
            return image.map(Optional.some)
        } else if let placeholderRenderer {
            return placeholderRenderer.renderImageWithData(data)
                .observe(on: uiScheduler)
                .take(
                    // Keep listening if rendering completes without a value (for example, on failure).
                    untilReplacement: image.concat(.never)
                )
                .map(Optional.some)
        } else {
            return image.map(Optional.some).prefix(value: nil)
        }
    }
}
