//
//  HTTPRequest.swift
//  SwiftCGI
//
//  Created by Todd Bluhm on 9/23/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case HEAD = "HEAD"
}

class HTTPRequest {
    var body: String?
    var method: HTTPMethod?
    var urlPath: String?
    var headers: [String:String]?
    
    init() {}
    
    init(method: HTTPMethod, urlPath: String, headers: [String:String]?, body: String?) {
        self.method = method
        self.urlPath = urlPath
        self.headers = headers
        self.body = body
    }
}