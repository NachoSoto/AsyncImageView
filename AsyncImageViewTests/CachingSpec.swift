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

import AsyncImageView

private func testCache<T: CacheType>(
	cacheCreator: @escaping () -> T,
	keyCreator: @escaping () -> T.Key,
	valueCreator: @escaping () -> T.Value
)
	where T.Value: Equatable
{
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
				cacheCreator: { InMemoryCache<String, String>(cacheName: "test") },
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
				return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
					.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
			}

			testCache(
				cacheCreator: { () -> DiskCache<String, String> in
					return DiskCache(rootDirectory: directoryCreator())
				},
				keyCreator: String.randomReadableString,
				valueCreator: String.randomReadableString
			)

			it("saves files in subdirectory") {
				func readFile(_ url: URL) -> String? {
					return (try? Data(contentsOf: url))
						.flatMap { NSString(data: $0, encoding: String.encoding.rawValue) as String? }
				}

				let directory = directoryCreator()
				let cache = DiskCache<String, String>(rootDirectory: directory)

				cache.setValue("hello", forKey: "word")
				cache.setValue("hi", forKey: "apple")

				expect(readFile(directory.appendingPathComponent("4").appendingPathComponent("word"))) == "hello"
				expect(readFile(directory.appendingPathComponent("5").appendingPathComponent("apple"))) == "hi"
			}
		}
	}
}

class RenderDataTypeCacheSubdirectorySpec: QuickSpec {
	override func spec() {
		it("works with integer sizes") {
			expect(subdirectoryForSize(CGSize(width: 15.0, height: 10.0))) == "15.00x10.00"
		}

		it("has limited precision") {
			expect(subdirectoryForSize(CGSize(width: 15.1245, height: 10.6123))) == "15.12x10.61"
		}
	}
}

extension String: DataFileType {
	public var subdirectory: String? {
		return "\(self.count)"
	}

	public var uniqueFilename: String {
		return self
	}
}

extension String: NSDataConvertible {
	public init?(data: Data) {
		self.init(data: data, encoding: String.encoding)
	}

	public var data: Data? {
		return (self as NSString).data(using: String.encoding.rawValue)
	}

	fileprivate static var encoding: String.Encoding {
		return .utf8
	}
}

private let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

extension String {
	fileprivate static func randomReadableString() -> String {
        return self.random(ofLength: UInt(Int.random(in: 1...15, using: &generator)),
                           from: alphabet,
                           using: &generator)!
	}
}
