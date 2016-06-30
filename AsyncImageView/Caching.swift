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
	func valueForKey(_ key: Key) -> Value?

	/// Sets a value for a key. If `value` is `nil`, it will be removed.
	func setValue(_ value: Value?, forKey key: Key)
}

// MARK: -

/// `CacheType` backed by `NSCache`.
public final class InMemoryCache<K: Hashable, V>: CacheType {
	private typealias NativeCacheType = Cache<CacheKey<K>, CacheValue<V>>

	private let cache: NativeCacheType

	public init(cacheName: String) {
		self.cache = {
			let cache = NativeCacheType()
			cache.name = cacheName

			return cache
		}()
	}

	public func valueForKey(_ key: K) -> V? {
		return cache.object(forKey: CacheKey(value: key))?.value
	}

	public func setValue(_ value: V?, forKey key: K) {
		let key = CacheKey(value: key)

		if let value = value.map(CacheValue.init) {
			cache.setObject(value, forKey: key)
		} else {
			cache.removeObject(forKey: key)
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

	private override func isEqual(_ object: AnyObject?) -> Bool {
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
	init?(data: Data)

	/// Encodes the receiver in `NSData`. Returns `nil` if failed.
	var data: Data? { get }
}

/// Returns the directory where all `DiskCache` caches are stored
/// by default.
public func diskCacheDefaultCacheDirectory() -> URL {
	return try! FileManager()
		.urlForDirectory(.cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
		.appendingPathComponent("AsyncImageView", isDirectory: true)
}

/// `CacheType` backed by files on disk.
public final class DiskCache<K: DataFileType, V: NSDataConvertible>: CacheType {
	private let rootDirectory: URL
	private let fileManager = FileManager.default()
	private let lock: Lock

	public static func onCacheSubdirectory(_ directoryName: String) -> DiskCache {
		let url = try! diskCacheDefaultCacheDirectory()
			.appendingPathComponent(directoryName, isDirectory: true)

		return DiskCache(rootDirectory: url)
	}

	public init(rootDirectory: URL) {
		self.rootDirectory = rootDirectory
		self.lock = Lock()
		self.lock.name = "DiskCache.\(rootDirectory.absoluteString)"
	}

	public func valueForKey(_ key: K) -> V? {
		return withLock { (try? Data(contentsOf: self.filePathForKey(key))) }
			.flatMap(V.init)
	}

	public func setValue(_ value: V?, forKey key: K) {
		let url = self.filePathForKey(key)

		self.withLock {
			self.guaranteeDirectoryExists(try! url.deletingLastPathComponent())

			if let data = value.flatMap({ $0.data }) {
				try! data.write(to: url, options: .dataWritingAtomic)
			} else if self.fileManager.fileExists(atPath: url.path!) {
				try! self.fileManager.removeItem(at: url)
			}
		}
	}

	private func withLock<T>(_ block: () -> T) -> T {
		self.lock.lock()
		let result = block()
		self.lock.unlock()

		return result
	}

	private func filePathForKey(_ key: K) -> URL {
		if let subdirectory = key.subdirectory {
			return try! self.rootDirectory
				.appendingPathComponent(subdirectory, isDirectory: true)
				.appendingPathComponent(key.uniqueFilename, isDirectory: false)
		} else {
			return try! self.rootDirectory
				.appendingPathComponent(key.uniqueFilename, isDirectory: false)
		}
	}

	private func guaranteeDirectoryExists(_ url: URL) {
		try! self.fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
	}
}
