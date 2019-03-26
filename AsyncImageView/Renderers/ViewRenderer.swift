//
//  ViewRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 02/24/17.
//  Copyright © 2017 Nacho Soto. All rights reserved.
//

import UIKit
import CoreGraphics

import ReactiveSwift

/// `RendererType` which generates a `UIImage` from a UIView.
@available(iOS 10.0, tvOSApplicationExtension 10.0,  *)
public final class ViewRenderer<Data: RenderDataType>: RendererType {
    public typealias Block = (_ data: Data) -> UIView
    
    private let format: UIGraphicsImageRendererFormat
    private let viewCreationBlock: Block
    
    /// - opaque: A Boolean flag indicating whether the bitmap is opaque.
    /// If you know the bitmap is fully opaque, specify YES to ignore the
    /// alpha channel and optimize the bitmap’s storage.
    public init(opaque: Bool, viewCreationBlock: @escaping Block) {
        self.format = UIGraphicsImageRendererFormat()
        self.format.opaque = opaque
        self.viewCreationBlock = viewCreationBlock
    }
    
    public func renderImageWithData(_ data: Data) -> SignalProducer<UIImage, Never> {
        return createProducer(
            data,
            viewCreationBlock: self.viewCreationBlock,
            renderBlock: { view in
                let renderer = UIGraphicsImageRenderer(
                    size: data.size,
                    format: self.format
                )
                
                return renderer.image { context in
                    draw(view: view, inContext: context.cgContext)
                }
            }
        )
    }
}

/// `RendererType` which generates a `UIImage` from a UIView.
public final class OldViewRenderer<Data: RenderDataType>: RendererType {
    public typealias Block = (_ data: Data) -> UIView
    
    private let opaque: Bool
    private let viewCreationBlock: Block
    
    /// - opaque: A Boolean flag indicating whether the bitmap is opaque.
    /// If you know the bitmap is fully opaque, specify YES to ignore the
    /// alpha channel and optimize the bitmap’s storage.
    public init(opaque: Bool, viewCreationBlock: @escaping Block) {
        self.opaque = opaque
        self.viewCreationBlock = viewCreationBlock
    }
    
    public func renderImageWithData(_ data: Data) -> SignalProducer<UIImage, Never> {
        return createProducer(
            data,
            viewCreationBlock: self.viewCreationBlock,
            renderBlock: { view in
                
                UIGraphicsBeginImageContextWithOptions(data.size, self.opaque, 0)
                defer { UIGraphicsEndImageContext() }
                
                draw(view: view, inContext: UIGraphicsGetCurrentContext()!)
                
                return UIGraphicsGetImageFromCurrentImageContext()!
            }
        )
    }
}

fileprivate func createProducer<Data: RenderDataType>(
    _ data: Data,
    viewCreationBlock: @escaping (_ data: Data) -> UIView,
    renderBlock: @escaping (UIView) -> UIImage
) -> SignalProducer<UIImage, Never> {
    return SignalProducer { observer, lifetime in
        let view = viewCreationBlock(data)
        view.frame.origin = .zero
        view.bounds.size = data.size
        view.layoutIfNeeded()
        
        // Make the CA renderer wait "until all the post-commit triggers fire".
        // We can't take a snapshot right away because the view has not been commited to the render server yet.
        DispatchQueue.main.async {
            if !lifetime.hasEnded {
                observer.send(value: renderBlock(view))
                observer.sendCompleted()
            }
        }
    }
        .start(on: UIScheduler())
}

fileprivate func draw(view: UIView, inContext context: CGContext) {
    view.layer.render(in: context)
}
