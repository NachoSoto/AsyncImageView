//
//  SynchronousUIScheduler.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 7/23/22.
//  Copyright © 2022 Nacho Soto. All rights reserved.
//

import Foundation

import ReactiveSwift

/// A scheduler that performs all work on the main thread, as soon as possible.
///
/// If the caller is already running on the main thread when an action is
/// scheduled, it will run synchronously, ignoring ordering of actions.
internal final class SynchronousUIScheduler: Scheduler {
    func schedule(_ action: @escaping () -> Void) -> Disposable? {
        let disposable = AnyDisposable()

        // If we're already running on the main thread just execute directly.
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async {
                if !disposable.isDisposed {
                    action()
                }
            }
        }

        return disposable
    }
}
