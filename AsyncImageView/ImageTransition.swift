import Foundation

/// Controls how a UIKit AsyncImageView presents an image replacement.
public enum ImageTransition: Equatable, Sendable {
    /// Preserve the default behavior: fade uncached images over 0.3 seconds and show cache hits immediately.
    case automatic
    /// Replace the image without animation, regardless of its cache status.
    case none
    /// Crossfade the image, including cache hits. A nonpositive duration disables animation.
    case crossfade(duration: TimeInterval = 0.3)

    internal func duration(cacheHit: Bool) -> TimeInterval? {
        switch self {
        case .automatic: cacheHit ? nil : fadeAnimationDuration
        case .none: nil
        case let .crossfade(duration): duration
        }
    }
}

/// Controls what a UIKit AsyncImageView displays while a replacement loads.
public enum ImagePlaceholderPolicy: Equatable, Sendable {
    /// Use the placeholder renderer, or clear the view if no placeholder renderer was supplied.
    case standard
    /// Retain the displayed image and skip the placeholder. Falls back to standard behavior if there is no image.
    case keepCurrentImage
}
