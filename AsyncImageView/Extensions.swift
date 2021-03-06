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
