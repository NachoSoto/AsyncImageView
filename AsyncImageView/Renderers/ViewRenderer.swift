//
//  ViewRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 02/24/17.
//  Copyright © 2017 Nacho Soto. All rights reserved.
//

import UIKit
import CoreGraphics

/// `SynchronousRendererType` which generates a `UIImage` from a UIView.
public final class ViewRenderer<Data: RenderDataType>: SynchronousRendererType {
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
    
    public func renderImageWithData(_ data: Data) -> UIImage {
        let view = self.viewCreationBlock(data)
        view.frame.origin = .zero
        view.bounds.size = data.size
        view.layoutIfNeeded()
        
        UIGraphicsBeginImageContextWithOptions(data.size, self.opaque, view.contentScaleFactor)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return snapshotImage
    }
}
