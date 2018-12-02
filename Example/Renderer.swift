//
//  Renderer.swift
//  Example
//
//  Created by Nacho Soto on 12/1/18.
//  Copyright © 2018 Nacho Soto. All rights reserved.
//

import Result
import ReactiveCocoa
import ReactiveSwift
import AsyncImageView

public struct Photos {
    typealias RendererType = AnyRenderer<Renderer.RasterizedRenderData, ImageResult, NoError>
    typealias ImageView = AsyncImageView<Renderer.RasterizedRenderData, Data, RendererType, RendererType>
    
    static func createAspectFillView(initialFrame frame: CGRect) -> ImageView {
        return ImageView(
            initialFrame: frame,
            renderer: Renderer.singleton.aspectFillRenderer
        )
    }
    
    static func createAspectFitView(initialFrame frame: CGRect) -> ImageView {
        return ImageView(
            initialFrame: frame,
            renderer: Renderer.singleton.aspectFitRenderer
        )
    }
    
    struct Data: ImageViewDataType {
        let imageData: FlickrImageData
        
        init(imageData: FlickrImageData) {
            self.imageData = imageData
        }
        
        func renderDataWithSize(_ size: CGSize) -> Renderer.RasterizedRenderData {
            return RenderData(imageData: self.imageData, size: size)
        }
    }
    
    public final class Renderer {
        private let remoteRenderer: RendererType
        let aspectFillRenderer: RendererType
        let aspectFitRenderer: RendererType
        
        static let singleton: Renderer = {
            return Renderer(screenScale: UIScreen.main.scale)
        }()
        
        init(screenScale: CGFloat) {
            self.remoteRenderer = AnyRenderer(
                RemoteImageRenderer<RemoteRenderData>(session: URLSession(configuration: URLSessionConfiguration.default))
                    plac
                    .logAndIgnoreErrors { print("Error downloading image: \($0)") }
                    .mapData { RemoteRenderData(imageData: $0.imageData, size: $0.size) }
                    .multicasted()
                )
            
            self.aspectFillRenderer = AnyRenderer(
                remoteRenderer
                    .inflatedWithScale(screenScale, opaque: true, contentMode: .aspectFill)
                    // Cache rasterized images. Not that important for this, but it can be useful
                    // if there is extra processing done to remote images (using RendererType.processedWithScale)
                    .withCache(DiskCache.onCacheSubdirectory("aspect_fill"))
                    .multicasted()
            )
            
            self.aspectFitRenderer = AnyRenderer(
                remoteRenderer
                    .inflatedWithScale(screenScale, opaque: true, contentMode: .aspectFit)
                    .withCache(DiskCache.onCacheSubdirectory("aspect_fit"))
                    .multicasted()
            )
        }
        
        // MARK: - RenderDataTypes
        
public struct RasterizedRenderData: RenderDataType, DataFileType {
    public let imageData: FlickrImageData
    public let size: CGSize
    
    public var uniqueFilename: String {
        return self.imageData.uniqueFilename
    }
}
        
        public struct RemoteRenderData: RemoteRenderDataType, DataFileType {
            public let imageData: FlickrImageData
            public let size: CGSize
            
            public var imageURL: URL {
                return self.imageData.url
            }
            
            public var subdirectory: String? {
                // We don't want to separate by size because the source image is the same.
                return nil
            }
            
            public var uniqueFilename: String {
                return self.imageData.uniqueFilename
            }
        }
    }
}

private extension FlickrImageData {
    var url: URL {
        return URL(string: "https://farm\(self.farm).static.flickr.com/\(self.server)/\(self.id)_\(self.secret).jpg")!
    }
    
    var uniqueFilename: String {
        return (url as NSURL)
            .resourceSpecifier!
            .addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
    }
}

extension Photos.Renderer.RemoteRenderData: Hashable {
    public static func ==(lhs: Photos.Renderer.RemoteRenderData, rhs: Photos.Renderer.RemoteRenderData) -> Bool {
        return (lhs.imageURL == rhs.imageURL)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.imageURL)
    }
}

extension Photos.Renderer.RasterizedRenderData: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.imageData)
        hasher.combine(self.size.width)
        hasher.combine(self.size.height)
    }
}
