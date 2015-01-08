//
//  HTTPTypes.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/7/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation

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

public enum ContentType: String {
    case TextHTML = "text/html"
    case TextPlain = "text/plain"
    case ApplicationJSON = "application/json"
}
