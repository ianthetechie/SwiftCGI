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

public struct HTTPResponse {
    // MARK: Stored Properties
    
    public var status: HTTPStatus
    public var contentType: HTTPContentType
    private var _headers: HTTPHeaderCollection<HTTPResponseHeader> = .Leaf
    public var headers: HTTPHeaderCollection<HTTPResponseHeader> {
        // Manually set the content length and content type. The latter is
        // set as a property at creation time, and the former is computed
        // dynamically. Both are obviously non-negotiable.
        var finalHeaders = _headers
        finalHeaders = setHeader(.ContentType(contentType), collection: finalHeaders)
        finalHeaders = setHeader(.ContentLength(contentLength), collection: finalHeaders)
        
        for header in _headers {
            finalHeaders = setHeader(header, collection: finalHeaders)
        }
        
        return finalHeaders
    }
    public var body: String
    
    
    // MARK: Computed properties
    
    public var contentLength: Int { return body.utf8.count }
    public var headerString: String {
        let httpStart = "HTTP/1.1 \(status.rawValue) \(status.description)"
        
        let httpHeaderString = headers.map({ header in "\(header.key): \(header.serializedValue)" }).joinWithSeparator(HTTPNewline)
        return [httpStart, httpHeaderString].joinWithSeparator(HTTPNewline) + HTTPTerminator
    }
    public var responseData: NSData? {
        let responseString = headerString + body as NSString
        return responseString.dataUsingEncoding(NSUTF8StringEncoding)
    }
    
    
    // MARK: Init
    
    public init(status: HTTPStatus, contentType: HTTPContentType, body: String) {
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
    
    
    // MARK: Helpers
    public mutating func setResponseHeader(header: HTTPResponseHeader) {
        switch header {
        case .ContentLength(_):
            fatalError("Content length cannot be set manually as it is dynamically computed")
        case .ContentType(let contentType):
            // If they want to set the content type this way, so be it...
            self.contentType = contentType
            return  // IMPORTANT: Early return; no need to set this in the internal collection
        default:
            break   // no more special behaviors
        }
        
        _headers = setHeader(header, collection: _headers)
    }
}
