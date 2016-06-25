//
//  Caching.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 9/17/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import Foundation

public protocol CacheType {
	associatedtype Key
	associatedtype Value

	/// Retrieves the value for this key.
	func valueForKey(key: Key) -> Value?

	/// Sets a value for a key. If `value` is `nil`, it will be removed.
	func setValue(value: Value?, forKey key: Key)
}

// MARK: -

/// `CacheType` backed by `NSCache`.
public final class InMemoryCache<K: Hashable, V>: CacheType {
	private let cache: NSCache

	public init(cacheName: String) {
		self.cache = {
			let cache = NSCache()
			cache.name = cacheName

			return cache
		}()
	}

	public func valueForKey(key: K) -> V? {
		return (cache.objectForKey(CacheKey(value: key)) as! CacheValue<V>?)?.value
	}

	public func setValue(value: V?, forKey key: K) {
		let key = CacheKey(value: key)

		if let value = value.map(CacheValue.init) {
			cache.setObject(value, forKey: key)
		} else {
			cache.removeObjectForKey(key)
		}
	}
}

private final class CacheValue<V>: NSObject {
	private let value: V

	init(value: V) {
		self.value = value
	}
}

private final class CacheKey<K: Hashable>: NSObject {
	private let value: K
	private let cachedHash: Int

	init(value: K) {
		self.value = value
		self.cachedHash = value.hashValue

		super.init()
	}

	private override func isEqual(object: AnyObject?) -> Bool {
		if let otherData = object as? CacheKey<K> {
			return otherData.value == self.value
		} else {
			return false
		}
	}

	private override var hash: Int {
		return self.cachedHash
	}
}

// MARK: -

/// Represents the key for a value that can be persisted on disk.
public protocol DataFileType {
	/// Optionally provide a subdirectory for this value.
	var subdirectory: String? { get }

	/// The string that can uniquely reference this value.
	var uniqueFilename: String { get }
}

/// Represents a value that can be persisted on disk.
public protocol NSDataConvertible {
	/// Creates an instance of the receiver from `NSData`, if possible.
	init?(data: NSData)

	/// Encodes the receiver in `NSData`. Returns `nil` if failed.
	var data: NSData? { get }
}

/// Returns the directory where all `DiskCache` caches are stored
/// by default.
public func diskCacheDefaultCacheDirectory() -> NSURL {
	return try! NSFileManager()
		.URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
		.URLByAppendingPathComponent("AsyncImageView", isDirectory: true)
}

/// `CacheType` backed by files on disk.
public final class DiskCache<K: DataFileType, V: NSDataConvertible>: CacheType {
	private let rootDirectory: NSURL
	private let fileManager = NSFileManager.defaultManager()
	private let lock: NSLock

	public static func onCacheSubdirectory(directoryName: String) -> DiskCache {
		let url = diskCacheDefaultCacheDirectory()
			.URLByAppendingPathComponent(directoryName, isDirectory: true)

		return DiskCache(rootDirectory: url)
	}

	public init(rootDirectory: NSURL) {
		self.rootDirectory = rootDirectory
		self.lock = NSLock()
		self.lock.name = "DiskCache.\(rootDirectory.absoluteString)"
	}

	public func valueForKey(key: K) -> V? {
		return withLock { NSData(contentsOfURL: self.filePathForKey(key)) }
			.flatMap(V.init)
	}

	public func setValue(value: V?, forKey key: K) {
		let url = self.filePathForKey(key)

		self.withLock {
			self.guaranteeDirectoryExists(url.URLByDeletingLastPathComponent!)

			if let data = value.flatMap({ $0.data }) {
				try! data.writeToURL(url, options: .DataWritingAtomic)
			} else if self.fileManager.fileExistsAtPath(url.path!) {
				try! self.fileManager.removeItemAtURL(url)
			}
		}
	}

	private func withLock<T>(block: () -> T) -> T {
		self.lock.lock()
		let result = block()
		self.lock.unlock()

		return result
	}

	private func filePathForKey(key: K) -> NSURL {
		if let subdirectory = key.subdirectory {
			return self.rootDirectory
				.URLByAppendingPathComponent(subdirectory, isDirectory: true)
				.URLByAppendingPathComponent(key.uniqueFilename, isDirectory: false)
		} else {
			return self.rootDirectory
				.URLByAppendingPathComponent(key.uniqueFilename, isDirectory: false)
		}
	}

	private func guaranteeDirectoryExists(url: NSURL) {
		try! self.fileManager.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
	}
}
