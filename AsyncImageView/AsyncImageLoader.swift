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
    @Published
    private(set) var renderResult: Renderer.RenderResult?
    
    init(
        requestsSignal: Signal<Data?, Never>,
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer?,
        uiScheduler: ReactiveSwift.Scheduler,
        imageCreationScheduler: ReactiveSwift.Scheduler) {

        requestsSignal
            .skipRepeats(==)
            .observe(on: uiScheduler)
            .on(value: { [weak self] in
                if let self = self,
                    placeholderRenderer == nil || $0 == nil {
                    self.resetImage()
                }
            })
            .observe(on: imageCreationScheduler)
            .flatMap(.latest) { data -> SignalProducer<Renderer.RenderResult, Never> in
                if let data = data {
                    if let placeholderRenderer = placeholderRenderer {
                        return placeholderRenderer
                            .renderImageWithData(data)
                            .take(untilReplacement: renderer.renderImageWithData(data))
                    } else {
                        return renderer.renderImageWithData(data)
                    }
                } else {
                    return .empty
                }
            }
        .observe(on: uiScheduler)
        .observeValues { [weak self] in
            self?.renderResult = $0
        }
    }
    
    private func resetImage() {
        // Avoid displaying a stale image.
        renderResult = nil
    }
}
