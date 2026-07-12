//
//  AsyncSwiftUIImageView.swift
//  AsyncImageView
//
//  Created by Javier Soto on 5/1/20.
//  Copyright © 2020 Nacho Soto. All rights reserved.
//

import SwiftUI
import ReactiveSwift

public struct AsyncSwiftUIImageView<
    Data: RenderDataType,
    ImageViewData: ImageViewDataType,
    Renderer: RendererType,
    PlaceholderRenderer: RendererType>: View
    where
    ImageViewData.RenderData == Data,
    Renderer.Data == Data,
    Renderer.Error == Never,
    PlaceholderRenderer.Data == Data,
    PlaceholderRenderer.Error == Never,
    Renderer.RenderResult == PlaceholderRenderer.RenderResult {
    private typealias ViewModel = AsyncSwiftUIImageViewModel<Data, ImageViewData, Renderer, PlaceholderRenderer>

    @State private var viewModelReference: LazyReference<ViewModel>

    private var viewModel: ViewModel {
        self.viewModelReference.value
    }

    public init(
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer? = nil
    ) {
        self.init(
            renderer: renderer,
            placeholderRenderer: placeholderRenderer,
            uiSchedulerFactory: { UIScheduler() },
            imageCreationSchedulerFactory: { QueueScheduler() }
        )
    }

    public init(
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer? = nil,
        uiScheduler: ReactiveSwift.Scheduler
    ) {
        self.init(
            renderer: renderer,
            placeholderRenderer: placeholderRenderer,
            uiSchedulerFactory: { uiScheduler },
            imageCreationSchedulerFactory: { QueueScheduler() }
        )
    }

    public init(
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer? = nil,
        imageCreationScheduler: ReactiveSwift.Scheduler
    ) {
        self.init(
            renderer: renderer,
            placeholderRenderer: placeholderRenderer,
            uiSchedulerFactory: { UIScheduler() },
            imageCreationSchedulerFactory: { imageCreationScheduler }
        )
    }

    public init(
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer? = nil,
        uiScheduler: ReactiveSwift.Scheduler,
        imageCreationScheduler: ReactiveSwift.Scheduler
    ) {
        self.init(
            renderer: renderer,
            placeholderRenderer: placeholderRenderer,
            uiSchedulerFactory: { uiScheduler },
            imageCreationSchedulerFactory: { imageCreationScheduler }
        )
    }

    internal init(
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer?,
        uiSchedulerFactory: @escaping () -> ReactiveSwift.Scheduler,
        imageCreationSchedulerFactory: @escaping () -> ReactiveSwift.Scheduler
    ) {
        _viewModelReference = State(
            initialValue: LazyReference {
                ViewModel(
                    renderer: renderer,
                    placeholderRenderer: placeholderRenderer,
                    uiScheduler: uiSchedulerFactory(),
                    imageCreationScheduler: imageCreationSchedulerFactory()
                )
            }
        )
    }

    public var data: ImageViewData? {
        didSet {
            self.requestImage()
        }
    }

    @State
    private var size: CGSize = .zero {
        didSet {
            if self.size != oldValue {
                self.requestImage()
            }
        }
    }

    public var body: some View {
        ZStack {
            self.imageView
        }
        .onGeometryChange(for: CGSize.self) { geometry in
            geometry.size
        } action: { imageSize in
            self.size = imageSize
        }
        .onAppear {
            self.viewModel.start()
            self.requestImage()
        }
        .onDisappear {
            self.viewModel.stop()
        }
    }

    @ViewBuilder
    private var imageView: some View {
        if let result = self.viewModel.renderResult {
            Image(uiImage: result.image)
                .resizable()
                .scaledToFit()
                .transition(
                    AnyTransition.opacity.animation(
                        result.cacheHit
                        ? nil
                        : .easeOut(duration: fadeAnimationDuration)
                    )
                )
        } else {
            Color.clear
        }
    }

    private func requestImage() {
        guard self.size.width > 0 && self.size.height > 0 else {
            return
        }

        self.viewModel.requestImage(self.data, size: self.size)
    }
}

private final class LazyReference<Value> {
    private let factory: () -> Value
    private lazy var storedValue = self.factory()

    var value: Value {
        self.storedValue
    }

    init(factory: @escaping () -> Value) {
        self.factory = factory
    }
}

public extension AsyncSwiftUIImageView {
    func data(_ data: ImageViewData) -> Self {
        var view = self
        view.data = data

        return view
    }
}

@Observable
private final class AsyncSwiftUIImageViewModel<
    Data: RenderDataType,
    ImageViewData: ImageViewDataType,
    Renderer: RendererType,
    PlaceholderRenderer: RendererType
>
    where
    ImageViewData.RenderData == Data,
    Renderer.Data == Data,
    Renderer.Error == Never,
    PlaceholderRenderer.Data == Data,
    PlaceholderRenderer.Error == Never,
    Renderer.RenderResult == PlaceholderRenderer.RenderResult {
    private typealias ImageLoader = AsyncImageLoader<Data, ImageViewData, Renderer, PlaceholderRenderer>

    private(set) var renderResult: Renderer.RenderResult?

    private let renderer: Renderer
    private let placeholderRenderer: PlaceholderRenderer?
    private let uiScheduler: ReactiveSwift.Scheduler
    private let imageCreationScheduler: ReactiveSwift.Scheduler

    private let requestsSignal: Signal<Data?, Never>
    private let requestsObserver: Signal<Data?, Never>.Observer
    @ObservationIgnored
    private var disposable: Disposable?

    init(
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer?,
        uiScheduler: ReactiveSwift.Scheduler,
        imageCreationScheduler: ReactiveSwift.Scheduler) {
        self.renderer = renderer
        self.placeholderRenderer = placeholderRenderer
        self.uiScheduler = uiScheduler
        self.imageCreationScheduler = imageCreationScheduler

        (self.requestsSignal, self.requestsObserver) = Signal.pipe()
    }

    func start() {
        self.disposable?.dispose()
        self.disposable = ImageLoader.createSignal(
            requestsSignal: self.requestsSignal,
            renderer: self.renderer,
            placeholderRenderer: self.placeholderRenderer,
            uiScheduler: self.uiScheduler
        )
        .observeValues { [weak self] result in
            self?.renderResult = result
        }
    }

    func stop() {
        self.disposable?.dispose()
        self.disposable = nil
    }

    func requestImage(_ data: ImageViewData?, size: CGSize) {
        self.imageCreationScheduler.schedule { [data, size, observer = self.requestsObserver] in
            observer.send(value: data?.renderDataWithSize(size))
        }
    }
}
