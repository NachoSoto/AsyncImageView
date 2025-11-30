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
    private typealias ImageLoader = AsyncImageLoader<Data, ImageViewData, Renderer, PlaceholderRenderer>
    private typealias RequestPipe = (signal: Signal<Data?, Never>, observer: Signal<Data?, Never>.Observer)

    private let renderer: Renderer
    private let placeholderRenderer: PlaceholderRenderer?
    private let uiScheduler: ReactiveSwift.Scheduler
    private let imageCreationScheduler: ReactiveSwift.Scheduler
    @State private var requestPipe: RequestPipe = Signal.pipe()
    private var requestsSignal: Signal<Data?, Never> { self.requestPipe.signal }
    
    public init(
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer? = nil,
        uiScheduler: ReactiveSwift.Scheduler = UIScheduler(),
        imageCreationScheduler: ReactiveSwift.Scheduler = QueueScheduler())
    {
        self.renderer = renderer
        self.placeholderRenderer = placeholderRenderer
        self.uiScheduler = uiScheduler
        self.imageCreationScheduler = imageCreationScheduler
    }

    @State private var renderResult: Renderer.RenderResult?
    @State private var disposable: Disposable?
    
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
            self.disposable?.dispose()
            self.disposable = ImageLoader.createSignal(
                requestsSignal: self.requestsSignal,
                renderer: self.renderer,
                placeholderRenderer: self.placeholderRenderer,
                uiScheduler: self.uiScheduler,
                imageCreationScheduler: self.imageCreationScheduler
            )
            .observeValues {
                self.renderResult = $0
            }

            self.requestImage()
        }
        .onDisappear {
            self.disposable?.dispose()
        }
    }

    @ViewBuilder
    private var imageView: some View {
        if let result = self.renderResult {
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

        let renderData = self.data?.renderDataWithSize(self.size)
        self.imageCreationScheduler.schedule { [renderData, weak observer = self.requestPipe.observer] in
            observer?.send(value: renderData)
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
