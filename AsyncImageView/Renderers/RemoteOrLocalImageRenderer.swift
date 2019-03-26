//
//  RemoteOrLocalImageRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 2/17/17.
//  Copyright © 2017 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveSwift

public enum RemoteOrLocalRenderData<Local: LocalRenderDataType, Remote: RemoteRenderDataType>: RenderDataType {
    case local(Local)
    case remote(Remote)
}

/// `RendererType` which downloads images and/or loads images from the bundle.
///
/// - seealso: RemoteImageRenderer
/// - seealso: LocalImageRenderer
public final class RemoteOrLocalImageRenderer<Local: LocalRenderDataType, Remote: RemoteRenderDataType>: RendererType {
    public typealias Data = RemoteOrLocalRenderData<Local, Remote>
    
    private let remoteRenderer: RemoteImageRenderer<Remote>
    private let localRenderer: LocalImageRenderer<Local>
    
    public init(session: URLSession, scheduler: Scheduler = QueueScheduler()) {
        self.remoteRenderer = RemoteImageRenderer(session: session)
        self.localRenderer = LocalImageRenderer(scheduler: scheduler)
    }
    
    public func renderImageWithData(_ data: Data) -> SignalProducer<UIImage, RemoteImageRendererError> {
        switch data {
        case let .remote(data):
            return self.remoteRenderer
                .renderImageWithData(data)
            
        case let .local(data):
            return self.localRenderer
                .renderImageWithData(data)
                .promoteError(RemoteImageRendererError.self)
        }
    }
}

extension RemoteOrLocalRenderData {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .local(data): hasher.combine(data)
        case let .remote(data): hasher.combine(data)
        }
    }
 
    public static func == (lhs: RemoteOrLocalRenderData, rhs: RemoteOrLocalRenderData) -> Bool {
        switch (lhs, rhs) {
        case let (.local(lhs), .local(rhs)): return lhs == rhs
        case let (.remote(lhs), .remote(rhs)): return lhs == rhs
        
        default: return false
        }
    }
    
    public var size: CGSize {
        switch self {
        case let .local(data): return data.size
        case let .remote(data): return data.size
        }
    }
}
