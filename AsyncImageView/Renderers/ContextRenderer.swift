//
//  ContextRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/27/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import CoreGraphics

/// `SynchronousRendererType` which generates a `UIImage` by rendering into a context.
@available(iOS 10.0, tvOSApplicationExtension 10.0,  *)
public final class ContextRenderer<Data: RenderDataType>: SynchronousRendererType {
    public typealias Block = (_ context: CGContext, _ data: Data) -> ()
    
    private let format: UIGraphicsImageRendererFormat
    private let imageSize: CGSize?
    private let renderingBlock: Block
    
    /// - opaque: A Boolean flag indicating whether the bitmap is opaque.
    /// If you know the bitmap is fully opaque, specify YES to ignore the
    /// alpha channel and optimize the bitmap’s storage.
    ///
    /// - imageSize: Optionally allows this Renderer to always create contexts of a constant size.
    ///              Useful for creating images that are going to be stretchable.
    public init(scale: CGFloat, opaque: Bool, imageSize: CGSize? = nil, renderingBlock: @escaping Block) {
        self.format = UIGraphicsImageRendererFormat()
        self.format.opaque = opaque
        self.format.scale = scale
        self.imageSize = imageSize
        self.renderingBlock = renderingBlock
    }
    
    public func renderImageWithData(_ data: Data) -> UIImage {
        let renderer = UIGraphicsImageRenderer(
            size: self.imageSize ?? data.size,
            format: self.format
        )
        
        return renderer.image { context in
            self.renderingBlock(context.cgContext, data)
        }
    }
}
