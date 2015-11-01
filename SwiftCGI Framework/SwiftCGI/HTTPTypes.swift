//
//  HTTPTypes.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/7/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

// MARK: Utility definitions

let HTTPNewline = "\r\n"
let HTTPTerminator = "\r\n\r\n"


// MARK: Simple enumerations

public enum HTTPMethod: String {
    case OPTIONS = "OPTIONS"
    case GET = "GET"
    case HEAD = "HEAD"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"
}

public enum Charset: String {
    case UTF8 = "utf-8"
}


// MARK: Status codes

public typealias HTTPStatusCode = Int
public enum HTTPStatus: HTTPStatusCode {
    case OK = 200
    case Created = 201
    case Accepted = 202
    
    case MovedPermanently = 301
    case SeeOther = 303
    case NotModified = 304
    case TemporaryRedirect = 307
    
    case BadRequest = 400
    case Unauthorized = 401
    case Forbidden = 403
    case NotFound = 404
    case MethodNotAllowed = 405
    case NotAcceptable = 406
    
    case InternalServerError = 500
    case NotImplemented = 501
    case ServiceUnavailable = 503
    
    var description: String {
        switch self {
        case .OK: return "OK"
        case .Created: return "Created"
        case .Accepted: return "Accepted"
            
        case .MovedPermanently: return "Moved Permanently"
        case .SeeOther: return "See Other"
        case .NotModified: return "Not Modified"
        case .TemporaryRedirect: return "Temporary Redirect"
            
        case .BadRequest: return "Bad Request"
        case .Unauthorized: return "Unauthorized"
        case .Forbidden: return "Forbidden"
        case .NotFound: return "Not Found"
        case .MethodNotAllowed: return "Method Not Allowed"
        case .NotAcceptable: return "Not Acceptable"
            
        case .InternalServerError: return "Internal Server Error"
        case .NotImplemented: return "Not Implemented"
        case .ServiceUnavailable: return "Service Unavailable"
        }
    }
}


// MARK: HTTP headers

// TODO: Unit test everything below this line
public protocol HTTPHeader: Equatable {
    var key: String { get }
    var serializedValue: String { get }
}

public func ==<T: HTTPHeader>(lhs: T, rhs: T) -> Bool {
    return lhs.key == rhs.key && lhs.serializedValue == rhs.serializedValue
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

public func isLeaf<T: HTTPHeader>(node: HTTPHeaderCollection<T>) -> Bool {
    switch node {
    case .Leaf:
        return true
    default:
        return false
    }
}

public func isTerminalValue<T: HTTPHeader>(node: HTTPHeaderCollection<T>) -> Bool {
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

func findMinimumNode<T: HTTPHeader>(collection: HTTPHeaderCollection<T>) -> T? {
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
        return "\(header.key): \(header.serializedValue)"
    }).joinWithSeparator(HTTPNewline)
}


// TODO: Finish adding all of the HTTP response headers
public enum HTTPResponseHeader: HTTPHeader {
    case ContentLength(Int)
    case ContentType(HTTPContentType)
    case SetCookie([String: String])
    
    public var key: String {
        switch self {
        case .ContentLength(_): return "Content-Length"
        case .ContentType(_): return "Content-Type"
        case .SetCookie(_): return "Set-Cookie"
        }
    }
    
    public var serializedValue: String {
        switch self {
        case .ContentLength(let length): return length.description
        case .ContentType(let contentType): return contentType.serializedValue
        case .SetCookie(let cookies): return cookies.map({ (key, value) in "\(key)=\(value)" }).joinWithSeparator("\(HTTPNewline)\(self.key): ")
        }
    }
}


// Note to future self and anyone else reading this code: additional types of generated data should
// be included here. If someone (including my future self) thinks of a good reason to include types
// such as video/mp4 that are typically used for static files, then there should be a VERY good use
// case for it. Web application frameworks are designed for dynamic response generation, not serving
// static files. nginx is perfectly good at that already. Notable exceptions to the "no static file
// types" rule are images, which have many valid dynamic generation use cases (QR codes, barcodes,
// transformations on uploaded files, etc).
public enum HTTPContentType {
    case TextHTML(Charset)
    case TextPlain(Charset)
    case ApplicationJSON
    case ImagePNG
    case ImageJPEG
    
    public var serializedValue: String {
        switch self {
        case .TextHTML(let charset): return "text/html; charset=\(charset.rawValue)"
        case .TextPlain(let charset): return "text/plain; charset=\(charset.rawValue)"
        case .ApplicationJSON: return "application/json"
        case .ImagePNG: return "image/png"
        case .ImageJPEG: return "image/jpeg"
        }
    }
}
