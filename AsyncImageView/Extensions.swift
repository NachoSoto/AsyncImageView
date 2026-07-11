//
//  Extensions.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/24/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

extension UIImage: NSDataConvertible {
	// init(data:) is already implemented by UIImage.

	public var data: Data? {
		return self.pngData()
	}

	public static func valueFromCacheData(_ data: Data) -> Self? {
		CachedImageSerialization.image(from: data) as? Self
	}

	public var cacheData: Data? {
		CachedImageSerialization.data(for: self)
	}
}

extension ImageResult: NSDataConvertible {
	public init?(data: Data) {
		if let image = UIImage(data: data) {
			self.init(
				image: image,
				cacheHit: false
			)
		} else {
			return nil
		}
	}

	public var data: Data? {
		return self.image.data
	}

	public static func valueFromCacheData(_ data: Data) -> ImageResult? {
		UIImage.valueFromCacheData(data).map { image in
			ImageResult(image: image, cacheHit: false)
		}
	}

	public var cacheData: Data? {
		self.image.cacheData
	}
}

private enum CachedImageSerialization {
	private static let currentVersion = 1

	private struct Payload: Codable {
		let version: Int
		let pngData: Data
		let scale: Double
	}

	static func data(for image: UIImage) -> Data? {
		guard let pngData = image.pngData() else { return nil }

		let payload = Payload(
			version: self.currentVersion,
			pngData: pngData,
			scale: Double(image.scale)
		)
		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary

		return try? encoder.encode(payload)
	}

	static func image(from data: Data) -> UIImage? {
		guard let payload = try? PropertyListDecoder().decode(Payload.self, from: data),
			payload.version == self.currentVersion,
			payload.scale.isFinite,
			payload.scale > 0,
			let image = UIImage(data: payload.pngData, scale: CGFloat(payload.scale)) else { return nil }

		return image
	}
}

extension Result {
    internal init(_ value: Success?, failWith error: @autoclosure () -> Failure) {
        if let value = value {
            self = .success(value)
        } else {
            self = .failure(error())
        }
    }
}
