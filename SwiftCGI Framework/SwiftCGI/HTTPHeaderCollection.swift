//
//  HTTPHeaderCollection.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/3/16.
//  Copyright © 2016 Ian Wagner. All rights reserved.
//

import Foundation

// TODO: This should probably be adjusted to be a red-black tree to maintain
// efficiency with large collections constructed in sorted order (which, I
// am guessing will be quite common...)
public enum HTTPHeaderCollection<T: HTTPHeader>: SequenceType, Equatable {
    case Leaf
    case Node(Box<HTTPHeaderCollection<T>>, Box<T>, Box<HTTPHeaderCollection<T>>)
    
    public typealias Generator = HTTPHeaderGenerator<T>
    public func generate() -> Generator {
        return HTTPHeaderGenerator(collection: self)
    }
}

public func ==<T: HTTPHeader>(lhs: HTTPHeaderCollection<T>, rhs: HTTPHeaderCollection<T>) -> Bool {
    if isLeaf(lhs) && isLeaf(rhs) {
        return true
    } else {
        switch lhs {
        case .Leaf:
            return false
        case .Node(let lhsLeft, let lhsValue, let lhsRight):
            switch rhs {
            case .Leaf:
                return false    // The first if statement established that both are not leaves, therefore lhs ≠ rhs
            case .Node(let rhsLeft, let rhsValue, let rhsRight):
                return lhsValue.unboxedValue == rhsValue.unboxedValue && lhsLeft.unboxedValue == rhsLeft.unboxedValue && lhsRight.unboxedValue == rhsRight.unboxedValue
            }
        }
    }
}

private func isLeaf<T: HTTPHeader>(node: HTTPHeaderCollection<T>) -> Bool {
    switch node {
    case .Leaf:
        return true
    default:
        return false
    }
}

private func isTerminalValue<T: HTTPHeader>(node: HTTPHeaderCollection<T>) -> Bool {
    switch node {
    case .Node(let left, _, let right):
        switch left.unboxedValue {
        case .Leaf:
            switch right.unboxedValue {
            case .Leaf:
                return true     // Both left and right are leaves
            default:
                break
            }
        default:
            break
        }
        return false
    case .Leaf:
        return true // leaves are terminal too
    }
}

private func findMinimumNode<T: HTTPHeader>(collection: HTTPHeaderCollection<T>) -> T? {
    switch collection {
    case .Leaf:
        return nil
    case .Node(let left, let value, _):
        if isLeaf(left.unboxedValue) {
            return value.unboxedValue
        } else {
            return findMinimumNode(left.unboxedValue)
        }
    }
}

public func getHeaderForKey<T: HTTPHeader>(key: String, collection: HTTPHeaderCollection<T>) -> T? {
    switch collection {
    case .Leaf:
        return nil
    case .Node(let left, let boxedValue, let right):
        let value = boxedValue.unboxedValue
        if value.key == key {
            return value
        } else if key < value.key {
            return getHeaderForKey(key, collection: left.unboxedValue)
        } else {
            return getHeaderForKey(key, collection: right.unboxedValue)
        }
    }
}

public func removeHeaderForKey<T: HTTPHeader>(key: String, collection: HTTPHeaderCollection<T>) -> HTTPHeaderCollection<T> {
    switch collection {
    case .Leaf:
        return .Leaf
    case .Node(let left, let current, let right):
        if current.unboxedValue.key == key {   // Found the node to remove
            if isLeaf(left.unboxedValue) && isLeaf(right.unboxedValue) {
                return .Leaf    // No children to take care of
            } else if isLeaf(left.unboxedValue) {
                return right.unboxedValue
            } else if isLeaf(right.unboxedValue) {
                return left.unboxedValue
            } else {
                // The complicated case: we have two children that are non-terminal
                let minimumNode = findMinimumNode(right.unboxedValue)!     // This should never fail to unwrap
                return .Node(left, Box(minimumNode), Box(removeHeaderForKey(minimumNode.key, collection: right.unboxedValue)))
            }
        } else {
            return .Node(Box(removeHeaderForKey(key, collection: left.unboxedValue)), current, Box(removeHeaderForKey(key, collection: right.unboxedValue)))
        }
    }
}

public func setHeader<T: HTTPHeader>(header: T, collection: HTTPHeaderCollection<T>) -> HTTPHeaderCollection<T> {
    switch collection {
    case .Leaf:
        // In this case, we have traversed the tree hierarchy, but never encountered
        // a node with the correct key before hitting a leaf, so we just insert
        // a new node.
        return .Node(Box(.Leaf), Box(header), Box(.Leaf))
    case .Node(let left, let current, let right):
        if current.unboxedValue.key == header.key {
            return .Node(left, Box(header), right)
        } else if (header.key < current.unboxedValue.key) {
            return .Node(Box(setHeader(header, collection: left.unboxedValue)), current, right)
        } else {
            return .Node(left, current, Box(setHeader(header, collection: right.unboxedValue)))
        }
    }
}


func serializeHeaders<T: HTTPHeader>(headers: HTTPHeaderCollection<T>) -> String {
    return headers.map({ (header) -> String in
        return "\(header.key): \(header.headerSerializableValue)"
    }).joinWithSeparator(HTTPNewline)
}

public class HTTPHeaderGenerator<T: HTTPHeader>: GeneratorType {
    public typealias Element = T
    
    private var collection: HTTPHeaderCollection<T>
    
    init(collection: HTTPHeaderCollection<T>) {
        self.collection = collection
    }
    
    public func next() -> Element? {
        switch collection {
        case .Leaf:
            return nil
        case .Node(_, let current, _):
            // Remove current from the internal tree, then return current
            collection = removeHeaderForKey(current.unboxedValue.key, collection: collection)
            return current.unboxedValue
        }
    }
}
