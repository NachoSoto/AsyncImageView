//
//  Helpers.swift
//  AsyncImageViewTests
//
//  Created by Nacho Soto on 6/11/18.
//  Copyright © 2018 Nacho Soto. All rights reserved.
//

import UIKit

internal extension CGSize {
    static func random() -> CGSize {
        return CGSize(
            width: Double.random(in: 1...200),
            height: Double.random(in: 1...200)
        )
    }
}

fileprivate let alphabet = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

internal extension String {
    static func randomReadableString() -> String {
        let length = Int.random(in: 1...15)
        return String(
            (1..<length)
                .map { _ in alphabet.randomElement()! }
        )
    }
}
