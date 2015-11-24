//
//  CachingSpec.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/24/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import Quick
import Nimble

import RandomKit

@testable import AsyncImageView

private func testCache<T: CacheType where T.Value: Equatable>(cacheCreator cacheCreator: () -> T, keyCreator: () -> T.Key, valueCreator: () -> T.Value) {
	var cache: T!

	beforeEach {
		cache = cacheCreator()
	}

	it("returns nil when not cached") {
		expect(cache.valueForKey(keyCreator())).to(beNil())
	}

	it("recovers value after saving it") {
		let key = keyCreator()
		let value = valueCreator()

		cache.setValue(value, forKey: key)

		expect(cache.valueForKey(key)) == value
	}

	it("can remove a value") {
		let key = keyCreator()
		let value = valueCreator()

		cache.setValue(value, forKey: key)
		cache.setValue(nil, forKey: key)

		expect(cache.valueForKey(key)).to(beNil())
	}
}

class InMemoryCacheSpec: QuickSpec {
	override func spec() {
		describe("InMemoryCache") {
			testCache(
				cacheCreator: { InMemoryCache(cacheName: "test") },
				keyCreator: String.random,
				valueCreator: String.random
			)
		}
	}
}
