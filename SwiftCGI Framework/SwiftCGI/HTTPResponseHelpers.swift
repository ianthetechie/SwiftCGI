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

private let HTTPNewline = "\r\n"
private let HTTPTerminator = "\r\n\r\n"

public struct HTTPResponse {
    // MARK: Stored Properties
    
    public let status: HTTPStatus
    public let contentType: ContentType
    public var headers: [String: String] = [:]    // TODO use an enumearation for the key
    public let body: String
    
    
    // MARK: Computed properties
    
    public var contentLength: Int { return countElements(body.utf8) }
    public var headerString: String {
        // TODO: Clean this up a bit and use a dict with enumerated keys as mentioned above
        let basicHeaders = [
            "HTTP/1.1 \(status.rawValue) \(status.description)",
            "Content-Type: \(contentType.rawValue)",
            "Content-Length: \(contentLength)"
        ]
        let additionalHeaderString = HTTPNewline.join(map(self.headers, { (key, value) in "\(key): \(value)" }))
        return HTTPNewline.join([HTTPNewline.join(basicHeaders), additionalHeaderString]) + HTTPTerminator
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
