//
//  CachingSpec.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/24/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import CoreGraphics
import Foundation
import Testing

@testable import AsyncImageView

@Suite
struct CachingTests {
	@Test
	func inMemoryCacheFulfillsCacheContract() {
		let cache = InMemoryCache<String, String>(cacheName: #function)

		verifyCacheContract(cache)
	}

	@Test
	func diskCacheFulfillsCacheContract() {
		let cache = DiskCache<String, String>(rootDirectory: makeTemporaryDirectory())

		verifyCacheContract(cache)
	}

	@Test
	func diskCacheSavesFilesInValueSubdirectories() {
		func readFile(_ url: URL) -> String? {
			(try? Data(contentsOf: url))
				.flatMap { NSString(data: $0, encoding: String.Encoding.utf8.rawValue) as String? }
		}

		let directory = makeTemporaryDirectory()
		let cache = DiskCache<String, String>(rootDirectory: directory)

		cache.setValue("hello", forKey: "word")
		cache.setValue("hi", forKey: "apple")

		#expect(readFile(directory.appendingPathComponent("4").appendingPathComponent("word")) == "hello")
		#expect(readFile(directory.appendingPathComponent("5").appendingPathComponent("apple")) == "hi")
	}

	@Test(
		arguments: [
			(CGSize(width: 15, height: 10), "15.00x10.00"),
			(CGSize(width: 15.1245, height: 10.6123), "15.12x10.61")
		]
	)
	func cacheSubdirectoryUsesFixedPrecision(size: CGSize, expected: String) {
		#expect(subdirectoryForSize(size) == expected)
	}

	@Test
	func cacheSubdirectoryUsesStableDefaultLocale() {
		let size = CGSize(width: 15.1245, height: 10.6123)

		#expect(subdirectoryForSize(size, locale: Locale(identifier: "fr_FR")) == "15,12x10,61")
		#expect(subdirectoryForSize(size) == "15.12x10.61")
	}
}

private func verifyCacheContract<Cache: CacheType>(_ cache: Cache)
where Cache.Key == String, Cache.Value == String {
	let missingKey = UUID().uuidString
	let firstKey = UUID().uuidString
	let secondKey = UUID().uuidString
	let firstValue = "first-value"
	let secondValue = "second-value"

	#expect(cache.valueForKey(missingKey) == nil)

	cache.setValue(firstValue, forKey: firstKey)
	cache.setValue(secondValue, forKey: secondKey)

	#expect(cache.valueForKey(firstKey) == firstValue)
	#expect(cache.valueForKey(secondKey) == secondValue)

	cache.setValue(nil, forKey: firstKey)

	#expect(cache.valueForKey(firstKey) == nil)
	#expect(cache.valueForKey(secondKey) == secondValue)
}

private func makeTemporaryDirectory() -> URL {
	URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
		.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
}

extension String: DataFileType {
	public var subdirectory: String? {
		"\(self.count)"
	}

	public var uniqueFilename: String {
		self
	}
}

extension String: NSDataConvertible {
	public init?(data: Data) {
		self.init(data: data, encoding: .utf8)
	}

	public var data: Data? {
		(self as NSString).data(using: String.Encoding.utf8.rawValue)
	}
}
