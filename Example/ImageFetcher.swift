//
//  ImageFetcher.swift
//  Example
//
//  Created by Nacho Soto on 11/30/18.
//  Copyright © 2018 Nacho Soto. All rights reserved.
//

import ReactiveSwift
import Result

public final class ImageFetcher {
    private let urlSession: URLSession = {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        return session
    }()
    
    private let decoder = JSONDecoder()
    
    public init() {
        precondition(!ImageFetcher.apiKey.isEmpty, "No API key was provided")
    }
    
    public func fetchImages(query: String) -> SignalProducer<[FlickrImageData], Error> {
        func decodeJSON(data: Data) -> Result<Response, Error> {
            return Result(try decoder.decode(Response.self, from: data))
                .mapError(Error.invalidJSON)
        }
        
        return self.urlSession.reactive.data(with: self.requestForQuery(query))
            .mapError(Error.networkError)
            .map { data, _ in data } // ignore response
            .attemptMap(decodeJSON)
            .map { $0.photos.photo }
    }
    
    private func requestForQuery(_ query: String) -> URLRequest {
        var components = URLComponents()
        components.scheme = ImageFetcher.endpointScheme
        components.host = ImageFetcher.endpointHost
        components.path = ImageFetcher.endpointPath
        components.queryItems = [
            URLQueryItem(name: "method", value: "flickr.photos.search"),
            URLQueryItem(name: "api_key", value: ImageFetcher.apiKey),
            URLQueryItem(name: "format", value: ImageFetcher.format),
            URLQueryItem(name: "nojsoncallback", value: "1"),
            URLQueryItem(name: "text", value: query)
        ]
        
        return URLRequest(url: components.url!)
    }
    
    // MARK: -
    
    public enum Error: Swift.Error {
        case networkError(originalError: AnyError)
        case invalidJSON(originalError: AnyError)
    }
    
    // MARK: -
    
    private static let endpointScheme: String = "https"
    private static let endpointHost: String = "api.flickr.com"
    private static let endpointPath: String = "/services/rest"
    private static let apiKey: String = ""
    private static let format: String = "json"
}

private struct Response: Decodable {
    struct Photos: Decodable {
        let photo: [FlickrImageData]
    }
    
    let photos: Photos
}
