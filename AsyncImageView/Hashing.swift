//
//  Hashing.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 7/12/15.
//  Copyright (c) 2015 Nacho Soto. All rights reserved.
//

infix operator ^^^ { associativity left precedence 160 }

internal func ^^^<L: Hashable, R: Hashable>(left: L, right: R) -> Int {
	return hash(left, right)
}

internal func ^^^<R: Hashable>(left: Int, right: R) -> Int {
	return hash(left, right)
}

internal func ^^^<L: Hashable>(left: L, right: Int) -> Int {
	return hash(right, left)
}

internal func ^^^<L: Hashable, R: Hashable>(left: L, right: R?) -> Int {
	return hash(left, right)
}

internal func ^^^<L: Hashable, R: Hashable>(left: L?, right: R) -> Int {
	return hash(right, left)
}

internal func ^^^<L: Hashable, R: Hashable>(left: L, right: [R]) -> Int {
	return hash(left, right)
}

internal func ^^^<L: Hashable, R: Hashable>(left: [L], right: R) -> Int {
	return hash(right, left)
}

extension SequenceType where Self.Generator.Element: Hashable {
	internal var hashValue: Int {
		return hash(self)
	}
}

// MARK: Private functions

private func hash<L: Hashable, R: Hashable>(left: L, _ right: R) -> Int {
	return hash(left.hashValue, right)
}

private func hash<L: Hashable, R: Hashable>(left: L, _ right: R?) -> Int {
	if let right = right {
		return hash(left, right)
	} else {
		return left.hashValue
	}
}

private func hash<L: Hashable, R: Hashable>(left: L, _ right: [R]) -> Int {
	return hash(left, hash(right))
}

private func hash<S: SequenceType where S.Generator.Element: Hashable>(sequence: S) -> Int {
	return sequence.reduce(0, combine: ^^^)
}

private func hash<R: Hashable>(left: Int, _ right: R) -> Int {
	return Int.addWithOverflow(Int.multiplyWithOverflow(left, HashingPrime).0, right.hashValue).0
}

private let HashingPrime: Int = 31
