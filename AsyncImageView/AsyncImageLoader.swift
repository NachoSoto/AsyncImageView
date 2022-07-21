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
    static func createSignal(
        requestsSignal: Signal<Data?, Never>,
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer?,
        uiScheduler: ReactiveSwift.Scheduler,
        imageCreationScheduler: ReactiveSwift.Scheduler
    ) -> Signal<Renderer.RenderResult?, Never> {
        return requestsSignal.skipRepeats(==)
            .observe(on: imageCreationScheduler)
            .flatMap(.latest) { data -> SignalProducer<Renderer.RenderResult?, Never> in
                let prefixSignal: SignalProducer<Renderer.RenderResult?, Never> = .init(value: nil)

                if let data = data {
                    if let placeholderRenderer = placeholderRenderer {
                        return placeholderRenderer
                            .renderImageWithData(data)
                            .observe(on: uiScheduler)
                            .take(
                                untilReplacement: renderer.renderImageWithData(data)
                                // Don't allow a finishing signal to cancel replacement without a value (like if it failed)
                                    .concat(.never)
                            )
                            .map(Optional.some)
                    } else {
                        return renderer
                            .renderImageWithData(data)
                            .observe(on: uiScheduler)
                            .map(Optional.some)
                            .prefix(prefixSignal)
                    }
                } else {
                    return prefixSignal
                }
            }
    }
}
