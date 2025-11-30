//
//  CachingSpec.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/24/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import Quick
import Nimble
import Foundation
import CoreGraphics

import AsyncImageView

class InMemoryCacheSpec: QuickSpec {
	override class func spec() {
		describe("InMemoryCache") {
			var cache: InMemoryCache<String, String>!

			beforeEach {
				cache = InMemoryCache(cacheName: "test")
			}

			it("returns nil when not cached") {
				expect(cache.valueForKey(UUID().uuidString)).to(beNil())
			}

			it("recovers value after saving it") {
				let key = UUID().uuidString
				let value = String.randomReadableString()

				cache.setValue(value, forKey: key)

				expect(cache.valueForKey(key)) == value
			}

			it("values don't override") {
				let key1 = UUID().uuidString
				let key2 = UUID().uuidString
				let value1 = String.randomReadableString()
				let value2 = String.randomReadableString()

				cache.setValue(value1, forKey: key1)
				cache.setValue(value2, forKey: key2)

				expect(cache.valueForKey(key1)) == value1
				expect(cache.valueForKey(key2)) == value2
			}

			it("can remove a value") {
				let key = UUID().uuidString
				let value = String.randomReadableString()

				cache.setValue(value, forKey: key)
				cache.setValue(nil, forKey: key)

				expect(cache.valueForKey(key)).to(beNil())
			}
		}
	}
}

class DiskCacheSpec: QuickSpec {
	override class func spec() {
		describe("DiskCache") {
			let directoryCreator = {
				return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
					.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
			}

			var cache: DiskCache<String, String>!

			beforeEach {
				cache = DiskCache(rootDirectory: directoryCreator())
			}

			it("returns nil when not cached") {
				expect(cache.valueForKey(UUID().uuidString)).to(beNil())
			}

			it("recovers value after saving it") {
				let key = UUID().uuidString
				let value = String.randomReadableString()

				cache.setValue(value, forKey: key)

				expect(cache.valueForKey(key)) == value
			}

			it("values don't override") {
				let key1 = UUID().uuidString
				let key2 = UUID().uuidString
				let value1 = String.randomReadableString()
				let value2 = String.randomReadableString()

				cache.setValue(value1, forKey: key1)
				cache.setValue(value2, forKey: key2)

				expect(cache.valueForKey(key1)) == value1
				expect(cache.valueForKey(key2)) == value2
			}

			it("can remove a value") {
				let key = UUID().uuidString
				let value = String.randomReadableString()

				cache.setValue(value, forKey: key)
				cache.setValue(nil, forKey: key)

				expect(cache.valueForKey(key)).to(beNil())
			}

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
	override class func spec() {
		it("works with integer sizes") {
			expect(subdirectoryForSize(CGSize(width: 15.0, height: 10.0))) == "15.00x10.00"
		}

		it("has limited precision") {
			expect(subdirectoryForSize(CGSize(width: 15.1245, height: 10.6123))) == "15.12x10.61"
		}
	}
}

@retroactive extension String: DataFileType {
	public var subdirectory: String? {
		return "\(self.count)"
	}

	public var uniqueFilename: String {
		return self
	}
}

extension String: @retroactive NSDataConvertible {
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
