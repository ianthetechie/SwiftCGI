//
//  Util.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/13/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import AppKit

public class Box<T> {
    public let unboxedValue: T
    public init(_ value: T) { self.unboxedValue = value }
}


public func ==<T: Equatable>(lhs: Box<T>, rhs: Box<T>) -> Bool {
    return lhs.unboxedValue == rhs.unboxedValue
}