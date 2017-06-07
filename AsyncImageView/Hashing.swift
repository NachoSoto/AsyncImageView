//
//  Hashing.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 7/12/15.
//  Copyright (c) 2015 Nacho Soto. All rights reserved.
//

infix operator ^^^ : MultiplicationPrecedence

public func ^^^<L: Hashable, R: Hashable>(left: L, right: R) -> Int {
	return hash(left, right)
}

public func ^^^<R: Hashable>(left: Int, right: R) -> Int {
	return hash(left, right)
}

public func ^^^<L: Hashable>(left: L, right: Int) -> Int {
	return hash(right, left)
}

public func ^^^<L: Hashable, R: Hashable>(left: L, right: R?) -> Int {
	return hash(left, right)
}

public func ^^^<L: Hashable, R: Hashable>(left: L?, right: R) -> Int {
	return hash(right, left)
}

public func ^^^<L: Hashable, R: Hashable>(left: L, right: [R]) -> Int {
	return hash(left, right)
}

public func ^^^<L: Hashable, R: Hashable>(left: [L], right: R) -> Int {
	return hash(right, left)
}

// MARK: Extensions

extension CGSize: Hashable {
    public var hashValue: Int {
        return self.width ^^^ self.height
    }
}

extension Sequence where Self.Iterator.Element: Hashable {
	public var hashValue: Int {
		return hash(self)
	}
}

// MARK: Private functions

private func hash<L: Hashable, R: Hashable>(_ left: L, _ right: R) -> Int {
	return hash(left.hashValue, right)
}

private func hash<L: Hashable, R: Hashable>(_ left: L, _ right: R?) -> Int {
	if let right = right {
		return hash(left, right)
	} else {
		return left.hashValue
	}
}

private func hash<L: Hashable, R: Hashable>(_ left: L, _ right: [R]) -> Int {
	return hash(left, hash(right))
}

private func hash<S: Sequence>(_ sequence: S) -> Int where S.Iterator.Element: Hashable {
	return sequence.reduce(0, ^^^)
}

private func hash<R: Hashable>(_ left: Int, _ right: R) -> Int {
    return left
        .multipliedReportingOverflow(by: HashingPrime).partialValue
        .addingReportingOverflow(right.hashValue).partialValue
}

private let HashingPrime: Int = 31
