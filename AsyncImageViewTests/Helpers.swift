//
//  Helpers.swift
//  AsyncImageViewTests
//
//  Created by Nacho Soto on 6/11/18.
//  Copyright © 2018 Nacho Soto. All rights reserved.
//

import UIKit

@discardableResult
internal func eventually(
    timeout: TimeInterval = 1,
    pollInterval: TimeInterval = 0.01,
    _ condition: () -> Bool
) -> Bool {
    let deadline = Date(timeIntervalSinceNow: timeout)

    repeat {
        if condition() {
            return true
        }

        RunLoop.current.run(until: Date(timeIntervalSinceNow: pollInterval))
    } while Date() < deadline

    return condition()
}

@MainActor
internal func eventuallyOnMainActor(
    timeout: TimeInterval = 1,
    pollInterval: TimeInterval = 0.01,
    _ condition: () -> Bool
) async -> Bool {
    let deadline = Date(timeIntervalSinceNow: timeout)

    repeat {
        if condition() {
            return true
        }

        try? await Task.sleep(for: .seconds(pollInterval))
    } while Date() < deadline

    return condition()
}

internal extension CGRect {
    func isApproximatelyEqual(to other: CGRect, tolerance: CGFloat = 0.001) -> Bool {
        abs(self.origin.x - other.origin.x) <= tolerance &&
            abs(self.origin.y - other.origin.y) <= tolerance &&
            abs(self.size.width - other.size.width) <= tolerance &&
            abs(self.size.height - other.size.height) <= tolerance
    }
}
