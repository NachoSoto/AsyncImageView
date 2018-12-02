//
//  FlickrImageData.swift
//  Example
//
//  Created by Nacho Soto on 11/30/18.
//  Copyright © 2018 Nacho Soto. All rights reserved.
//

/// Uniquely identifies an image in Flickr
public struct FlickrImageData: Hashable, Decodable {
    public let id: String
    public let secret: String
    public let farm: Int
    public let server: String
}
