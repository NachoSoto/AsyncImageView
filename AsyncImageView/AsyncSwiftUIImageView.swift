//
//  AsyncSwiftUIImageView.swift
//  AsyncImageView
//
//  Created by Javier Soto on 5/1/20.
//  Copyright © 2020 Nacho Soto. All rights reserved.
//

import SwiftUI
import Combine
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

    private let renderer: Renderer
    private let placeholderRenderer: PlaceholderRenderer?
    private let uiScheduler: ReactiveSwift.Scheduler

    private let imageCreationScheduler: ReactiveSwift.Scheduler

    public init(
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer? = nil,
        uiScheduler: ReactiveSwift.Scheduler = UIScheduler(),
        imageCreationScheduler: ReactiveSwift.Scheduler = QueueScheduler()) {
        self.renderer = renderer
        self.placeholderRenderer = placeholderRenderer
        self.uiScheduler = uiScheduler
        self.imageCreationScheduler = imageCreationScheduler
    }

    @StateObject private var viewModel = ViewModel()

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

            Color.clear
                .modifier(SizeModifier())
                .onPreferenceChange(ImageSizePreferenceKey.self) { imageSize in
                    self.size = imageSize
                }
        }
        .onAppear {
            self.viewModel.start(
                renderer: self.renderer,
                placeholderRenderer: self.placeholderRenderer,
                uiScheduler: self.uiScheduler,
                imageCreationScheduler: self.imageCreationScheduler
            )
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

        self.imageCreationScheduler.schedule { [data, size, viewModel = self.viewModel] in
            viewModel.requestImage(data?.renderDataWithSize(size))
        }
    }
}

public extension AsyncSwiftUIImageView {
    func data(_ data: ImageViewData) -> Self {
        var view = self
        view.data = data

        return view
    }
}

private struct ImageSizePreferenceKey: PreferenceKey {
    typealias Value = CGSize

    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct SizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ImageSizePreferenceKey.self, value: geometry.size)
            }
        )
    }
}

private final class AsyncSwiftUIImageViewModel<
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
    private typealias ImageLoader = AsyncImageLoader<Data, ImageViewData, Renderer, PlaceholderRenderer>

    @Published private(set) var renderResult: Renderer.RenderResult?

    private let requestsSignal: Signal<Data?, Never>
    private let requestsObserver: Signal<Data?, Never>.Observer
    private var disposable: Disposable?

    init() {
        (self.requestsSignal, self.requestsObserver) = Signal.pipe()
    }

    func start(
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer?,
        uiScheduler: ReactiveSwift.Scheduler,
        imageCreationScheduler: ReactiveSwift.Scheduler) {
        self.disposable?.dispose()
        self.disposable = ImageLoader.createSignal(
            requestsSignal: self.requestsSignal,
            renderer: renderer,
            placeholderRenderer: placeholderRenderer,
            uiScheduler: uiScheduler,
            imageCreationScheduler: imageCreationScheduler
        )
        .observeValues { [weak self] result in
            self?.renderResult = result
        }
    }

    func stop() {
        self.disposable?.dispose()
        self.disposable = nil
    }

    func requestImage(_ data: Data?) {
        self.requestsObserver.send(value: data)
    }
}
