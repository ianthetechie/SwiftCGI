//
//  Request.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 9/26/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import Foundation

public enum RequestCompletionStatus {
    case Complete
}

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case HEAD = "HEAD"
}

public protocol Request {
    var cookies: [String: String]? { get set }
    var params: RequestParams { get }   /// Used to store things like CGI environment variables
    var path: String { get }
    var streamData: NSMutableData? { get set }
    var socket: GCDAsyncSocket? { get set }
    var method: HTTPMethod { get }
    // TODO: Add in a real type for Request Headers
    var headers: [String: String]? { get }
    
    func finish(status: RequestCompletionStatus)
}