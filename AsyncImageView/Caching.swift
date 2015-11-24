//
//  Caching.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 9/17/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import Foundation

public protocol CacheType {
	typealias Key: Hashable
	typealias Value

	func valueForKey(key: Key) -> Value?
	func setValue(value: Value, forKey key: Key)
}

internal class InMemoryCache<K: Hashable, V>: CacheType {
	private let cache: NSCache

	init(cacheName: String) {
		self.cache = {
			let cache = NSCache()
			cache.name = cacheName

			return cache
		}()
	}

	func valueForKey(key: K) -> V? {
		return (cache.objectForKey(CacheKey(value: key)) as! CacheValue<V>?)?.value
	}

	func setValue(value: V, forKey key: K) {
		cache.setObject(CacheValue(value: value), forKey: CacheKey(value: key))
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
