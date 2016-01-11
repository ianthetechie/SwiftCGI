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

public enum HTTPRangeUnit: String {
    case Bytes = "bytes"
    case None = "none"
}

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

public enum HTTPCacheControlResponse {
    case Public
    case Private
    case NoCache
    case NoStore
    case NoTransform
    case MustRevalidate
    case ProxyRevalidate
    case MaxAge(Int)
    case SMaxAge(Int)
    case CacheExtension
}

extension HTTPCacheControlResponse: HTTPHeaderSerializable {
    public var headerSerializableValue: String {
        switch self {
        case .Public:
            return "public"
        case .Private:  // TODO: optional field name
            return "private"
        case .NoCache:  // TODO: optional field name
            return "no-cache"
        case .NoStore:
            return "no-store"
        case .NoTransform:
            return "no-transform"
        case .MustRevalidate:
            return "must-revalidate"
        case .ProxyRevalidate:
            return "proxy-revalidate"
        case .MaxAge(let seconds):
            return "max-age = \(seconds)"
        case .SMaxAge(let seconds):
            return "s-maxage = \(seconds)"
        case .CacheExtension:
            return "cache-extension"
        }
    }
}

public enum Charset: String {
    case UTF8 = "utf-8"
}


/// Types conforming to this protocol may be interpolated safely into an HTTP header line.
public protocol HTTPHeaderSerializable {
    var headerSerializableValue: String { get }
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
public protocol HTTPHeader: Equatable, HTTPHeaderSerializable {
    var key: String { get }
}

public func ==<T: HTTPHeader>(lhs: T, rhs: T) -> Bool {
    return lhs.key == rhs.key && lhs.headerSerializableValue == rhs.headerSerializableValue
}


// TODO: Finish adding all of the HTTP response headers
public enum HTTPResponseHeader: HTTPHeader {
    case AccessControlAllowOrigin(String)
    case AcceptPatch(HTTPContentType)
    case AcceptRanges(HTTPRangeUnit)
    case Age(Int)
    case Allow(HTTPMethod)
    case CacheControl(HTTPCacheControlResponse)
    case ContentLength(Int)
    case ContentType(HTTPContentType)
    case SetCookie([String: String])
    
    public var key: String {
        switch self {
        case .AccessControlAllowOrigin(_): return "Access-Control-Allow-Origin"
        case .AcceptPatch(_): return "Accept-Patch"
        case .AcceptRanges(_): return "Accept-Ranges"
        case .Age(_): return "Age"
        case .Allow(_): return "Allow"
        case .CacheControl(_): return "Cache-Control"
        case .ContentLength(_): return "Content-Length"
        case .ContentType(_): return "Content-Type"
        case .SetCookie(_): return "Set-Cookie"
        }
    }
    
    public var headerSerializableValue: String {
        switch self {
        case .AccessControlAllowOrigin(let value): return value
        case .AcceptPatch(let value): return value.headerSerializableValue
        case .AcceptRanges(let value): return value.rawValue
        case .Age(let value): return String(value)
        case .Allow(let value): return value.rawValue
        case .CacheControl(let value): return value.headerSerializableValue
        case .ContentLength(let length): return String(length)
        case .ContentType(let type): return type.headerSerializableValue
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
public enum HTTPContentType: Equatable {
    case TextHTML(Charset)
    case TextPlain(Charset)
    case ApplicationJSON
    case ImagePNG
    case ImageJPEG
}

extension HTTPContentType: HTTPHeaderSerializable {
    public var headerSerializableValue: String {
        switch self {
        case .TextHTML(let charset): return "text/html; charset=\(charset.rawValue)"
        case .TextPlain(let charset): return "text/plain; charset=\(charset.rawValue)"
        case .ApplicationJSON: return "application/json"
        case .ImagePNG: return "image/png"
        case .ImageJPEG: return "image/jpeg"
        }
    }
}

public func ==(a: HTTPContentType, b: HTTPContentType) -> Bool {
    switch (a, b) {
    case (.TextHTML(let x), .TextHTML(let y)) where x == y:     return true
    case (.TextPlain(let x), .TextPlain(let y)) where x == y:   return true
    case (.ApplicationJSON, .ApplicationJSON):                  return true
    case (.ImagePNG, .ImagePNG):                                return true
    case (.ImageJPEG, .ImageJPEG):                              return true
    default:                                                    return false
    }
}
