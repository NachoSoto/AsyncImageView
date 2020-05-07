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
    private let requestsSignal: Signal<Data?, Never>
    private let requestsObserver: Signal<Data?, Never>.Observer
    
    private let imageCreationScheduler: ReactiveSwift.Scheduler
    
    public init(
        renderer: Renderer,
        placeholderRenderer: PlaceholderRenderer? = nil,
        uiScheduler: ReactiveSwift.Scheduler = UIScheduler(),
        imageCreationScheduler: ReactiveSwift.Scheduler = QueueScheduler())
    {
        (self.requestsSignal, self.requestsObserver) = Signal.pipe()
        self.imageCreationScheduler = imageCreationScheduler
        
        self.loader = AsyncImageLoader(
            requestsSignal: requestsSignal,
            renderer: renderer,
            placeholderRenderer: placeholderRenderer,
            uiScheduler: uiScheduler,
            imageCreationScheduler: imageCreationScheduler
        )
    }
    
    @ObservedObject
    private var loader: AsyncImageLoader<Data, ImageViewData, Renderer, PlaceholderRenderer>
    
    public var data: ImageViewData? {
        didSet {
            requestImage()
        }
    }
    
    @State
    private var size: CGSize = .zero {
        didSet {
            if size != oldValue {
                requestImage()
            }
        }
    }
    
    public var body: some View {
        Group {
            if self.loader.renderResult != nil {
                Image(uiImage: self.loader.renderResult!.image)
                    .resizable()
                    .scaledToFit()
                    .transition(
                        AnyTransition.opacity.animation(
                            (self.loader.renderResult?.cacheHit ?? false)
                                ? nil
                                : .easeOut(duration: fadeAnimationDuration)
                        )
                )
            } else {
                Rectangle()
                    .fill(Color.clear)
            }
        }
        .modifier(SizeModifier())
        .onPreferenceChange(ImageSizePreferenceKey.self) { imageSize in
            self.size = imageSize
        }
    }
    
    private func requestImage() {
        guard size.width > 0 && size.height > 0 else { return }
        
        imageCreationScheduler.schedule { [data, size, weak observer = self.requestsObserver] in
            observer?.send(value: data?.renderDataWithSize(size))
        }
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
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: ImageSizePreferenceKey.self, value: geometry.size)
        }
    }

    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}
