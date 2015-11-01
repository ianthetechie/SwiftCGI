//
//  EmbeddedHTTPRequest.swift
//  SwiftCGI
//
//  Created by Todd Bluhm on 9/23/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import Foundation


struct EmbeddedHTTPRequest {
    var cookies: [String: String]? = [:]
    var streamData: NSMutableData?
    var socket: GCDAsyncSocket?
    let method: HTTPMethod
    let path: String
    let params: RequestParams
    var headers: [String: String]?
    
    init(pRequest: HTTPParserRequest) {
        // Get the Request Method
        guard let pRequestMethod = pRequest.method else {
            fatalError("HttpParserRequest has no method.")
        }
        
        guard let method = HTTPMethod(rawValue: pRequestMethod) else {
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
        
        // TODO: Load cookies
        
        // Get the Request body if one exits
        if let bodyData = pRequest.body?.dataUsingEncoding(NSUTF8StringEncoding) {
            streamData = NSMutableData(data: bodyData)
        }
        
        params = [:]
    }
}

extension EmbeddedHTTPRequest: Request {
    func finish(status: RequestCompletionStatus) {
        switch status {
        case .Complete:
            socket?.disconnectAfterWriting()
        }
    }
}
