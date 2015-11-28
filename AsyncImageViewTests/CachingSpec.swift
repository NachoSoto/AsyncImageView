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

	it("values don't override") {
		let key1 = keyCreator()
		let key2 = keyCreator()
		let value1 = valueCreator()
		let value2 = valueCreator()

		cache.setValue(value1, forKey: key1)
		cache.setValue(value2, forKey: key2)

		expect(cache.valueForKey(key1)) == value1
		expect(cache.valueForKey(key2)) == value2
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
				keyCreator: String.randomReadableString,
				valueCreator: String.randomReadableString
			)
		}
	}
}

class DiskCacheSpec: QuickSpec {
	override func spec() {
		describe("DiskCache") {
			let directoryCreator = {
				return NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
					.URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString, isDirectory: true)
			}

			testCache(
				cacheCreator: { () -> DiskCache<String, String> in
					return DiskCache(rootDirectory: directoryCreator())
				},
				keyCreator: String.randomReadableString,
				valueCreator: String.randomReadableString
			)

			it("saves files in subdirectory") {
				func readFile(url: NSURL) -> String? {
					return NSData(contentsOfURL: url)
						.flatMap { NSString(data: $0, encoding: String.encoding) as String? }
				}

				let directory = directoryCreator()
				let cache = DiskCache<String, String>(rootDirectory: directory)

				cache.setValue("hello", forKey: "word")
				cache.setValue("hi", forKey: "apple")

				expect(readFile(directory.URLByAppendingPathComponent("4").URLByAppendingPathComponent("word"))) == "hello"
				expect(readFile(directory.URLByAppendingPathComponent("5").URLByAppendingPathComponent("apple"))) == "hi"
			}
		}
	}
}

extension String: DataFileType {
	public var subdirectory: String? {
		return "\(self.characters.count)"
	}

	public var uniqueFilename: String {
		return self
	}
}

extension String: NSDataConvertible {
	public init?(data: NSData) {
		self.init(data: data, encoding: String.encoding)
	}

	public var data: NSData? {
		return (self as NSString).dataUsingEncoding(String.encoding)
	}

	private static var encoding: UInt {
		return NSUTF8StringEncoding
	}
}

private let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

extension String {
	private static func randomReadableString() -> String {
		return self.random(UInt(Int.random(1...15)), NSCharacterSet(charactersInString: alphabet))
	}
}
