//
//  HTTPResponseHelpers.swift
//  SwiftCGI
//
//  Copyright (c) 2014, Ian Wagner
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that thefollowing conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

public struct HTTPResponse {
    // MARK: Stored Properties
    
    public let status: HTTPStatus
    public let contentType: ContentType
    public let body: String
    
    
    // MARK: Computed properties
    
    public var contentLength: Int { return countElements(body.utf8) }
    public var headerString: String {
        return "HTTP/1.1 \(status.rawValue) \(status.description)\r\nContent-Type: \(contentType.rawValue)\r\nContent-Length: \(contentLength)\r\n\r\n"
    }
    public var responseData: NSData? {
        let responseString = headerString + body as NSString
        return responseString.dataUsingEncoding(NSUTF8StringEncoding)
    }
    
    
    // MARK: Init
    
    public init(status: HTTPStatus, contentType: ContentType, body: String) {
        self.status = status
        self.contentType = contentType
        self.body = body
    }
    
    // NOTE: The current Swift compiler doesn't allow convenience initializers
    // on structs, so the other initializer is not called
    public init(body: String) {
        status = .OK
        contentType = .TextHTML
        self.body = body
    }
}
