//
//  HTTPRequest.swift
//  SwiftCGI
//
//  Created by Todd Bluhm on 9/23/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import Foundation

//public protocol Request {
//    var cookies: [String: String]? { get set }
//    var params: RequestParams { get }   /// Used to store things like CGI environment variables
//    var path: String { get }
//    var streamData: NSMutableData? { get set }
//    var socket: GCDAsyncSocket? { get set }
//    var method: HTTPMethod { get }
//    // TODO: Add in a real type for Request Headers
//    var headers: [String: String] { get }
//    
//    func finish(status: RequestCompletionStatus)
//}

struct HTTPRequest {
    var cookies: [String: String]? = [:]
    var streamData: NSMutableData?
    var socket: GCDAsyncSocket?
    let method: HTTPMethod
    let path: String
    let params: RequestParams
    var headers: [String: String]?
    
    init(pRequest: HttpParserRequest) {
        // Get the Request Method
        guard let method = HTTPMethod(rawValue: pRequest.method!) else {
            fatalError("Could not parse out the HTTP request method")
        }
        self.method = method
        
        // Get the request path
        guard let path = pRequest.url else {
            fatalError("Can not read path from request")
        }
        self.path = path
        
        // Get the request headers
        if let headers = pRequest.headers {
            self.headers = headers
        }
        
        // Get the Request body if one exits
        if let bodyData = pRequest.body?.dataUsingEncoding(NSUTF8StringEncoding) {
            streamData = NSMutableData(data: bodyData)
        }
        
        params = [:]
    }
}

extension HTTPRequest: Request {
    func finish(status: RequestCompletionStatus) {
        switch status {
        case .Complete:
            socket?.disconnectAfterWriting()
        }
    }
}